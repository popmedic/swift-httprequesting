#!/bin/sh

GIT_HASH=`git rev-parse --short HEAD`
[ $? != 0 ] && rm -rf "${COVERAGE_GIST}" && exit 1
echo "► current commit hash: ${GIT_HASH}"

if [[ " $@ " =~ " +all " ]]; then
    echo "► linting..."
    swiftlint --strict
    [ $? != 0 ] && exit 1

    echo "► testing..."
    swift test --enable-code-coverage
    [ $? != 0 ] && exit 1
fi

echo "▶︎  LLVM REPORT  ◀︎"
BIN_PATH="$(swift build --show-bin-path)"
XCTEST_PATH="$(find ${BIN_PATH} -name '*.xctest')"

COV_BIN=$XCTEST_PATH
if [[ "$OSTYPE" == "darwin"* ]]; then
    f="$(basename $XCTEST_PATH .xctest)"
    COV_BIN="${COV_BIN}/Contents/MacOS/$f"
fi
LLVM_REPORT=`xcrun llvm-cov report \
             "${COV_BIN}" \
             -instr-profile=.build/debug/codecov/default.profdata \
             -ignore-filename-regex=".build|Tests"`
echo "${LLVM_REPORT}"
PERCENT=`echo "${LLVM_REPORT}" | \
         pcregrep -o1 "TOTAL\s+(.*)" | \
         pcregrep -o1 '([0-9\.]+)\s*' | \
         tail -n 1`

echo "► generating coverage..."
echo "   ► total: ${PERCENT}%"

if [[ " $@ " =~ " +update_badge " ]]; then
    echo "► uploading badge:"
    TMPL='<svg 
    xmlns="http://www.w3.org/2000/svg"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    width="128"
    height="44">
    <svg
        width="128"
        height="18"
         x="0"
         y="0">
        <text 
            x="6" 
            y="14" 
            height="100%" 
            width="100%"
            fill="#353535"
            stroke="none"
            style="
                font-size: 10pt;
                font-family: Menlo;
                text-anchor: left;
            "
        >
            {{LABEL}}
        </text>
    </svg>
    <svg 
        width="128"
        height="24"
         x="0"
         y="20">
        <rect 
            x="0" 
            y="0" 
            height="100%" 
            width="100%"
            stroke="lightgray"
            fill="#8c1515"
            rx="10px"
            ry="10px"
            style="
                stroke-width: 1px;
            "
        />
        <mask
            x="0"
            y="0"
            id="mask">
            <rect 
                fill="white" 
                width="{{PERCENT}}%" 
                height="100%" 
            />
        </mask>
        <rect 
            x="0" 
            y="0" 
            height="100%" 
            width="100%"
            stroke="lightgray"
            fill="#0a700a"
            rx="10px"
            ry="10px"
            style="
                stroke-width: 1px;
            "
            mask="url(#mask)"
        />
        <text 
            x="50%" 
            y="18" 
            height="100%" 
            width="50%"
            fill="white"
            stroke="none"
            style="
                font-size: 11pt;
                font-family: Menlo;
                text-anchor: middle;
            "
        >
        {{PERCENT}}%
        </text>
    </svg>
</svg>'
    
    LABEL="Code Coverage"
    GIST="a555f644f50b16b6dd3a04a28af6f293"
    COVERAGE_GIST=coverage.gist
    echo "   ► uploading badge for ${LABEL}..."
    GIST_URL="git@gist.github.com:${GIST}.git"
    COVERAGE_GIST=coverage.gist
    echo "   ► uploading badge for ${LABEL}..."
    echo "      ► cloning gist ${GIST_URL} into ${COVERAGE_GIST}..."
    git clone "${GIST_URL}" "${COVERAGE_GIST}" > /dev/null 2> /dev/null
    [ $? != 0 ] && exit 1
        
    SVG="swift-httprequesting-coverage.svg"
    echo "      ► creating SVG ${SVG}..."
        
    SVG_PATH="${COVERAGE_GIST}/${SVG}"
    echo "$TMPL" | \
        sed 's/{{PERCENT}}/'"${PERCENT}"'/' | \
        sed 's/{{LABEL}}/'"$(tr '[:lower:]' '[:upper:]' <<< ${LABEL:0:1})${LABEL:1}"'/' > \
        "${SVG_PATH}"
    [ $? != 0 ] && rm -rf "${COVERAGE_GIST}" && exit 1
    echo "      ► created SVG: \"${SVG_PATH}\""

    echo "      ► push badge ${LABEL}..."
    pushd "${COVERAGE_GIST}" > /dev/null
    [ $? != 0 ] && rm -rf "${COVERAGE_GIST}" && exit 1
    echo "      ► set commit \"coverage update: ${GIT_HASH}\""
    git commit -am "coverage update: ${GIT_HASH}" > /dev/null 2> /dev/null
    git push origin master > /dev/null 2> /dev/null
    popd > /dev/null
    [ $? != 0 ] && rm -rf "${COVERAGE_GIST}" && exit 1
    rm -rf "${COVERAGE_GIST}"
    echo "      ► clean up: ${COVERAGE_GIST}"
fi
