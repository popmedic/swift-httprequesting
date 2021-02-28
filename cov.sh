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

if [[ " $@ " =~ " +llvm_report " ]]; then
    echo "▶︎  LLVM REPORT  ◀︎"
    BIN_PATH="$(swift build --show-bin-path)"
    XCTEST_PATH="$(find ${BIN_PATH} -name '*.xctest')"

    COV_BIN=$XCTEST_PATH
    if [[ "$OSTYPE" == "darwin"* ]]; then
        f="$(basename $XCTEST_PATH .xctest)"
        COV_BIN="${COV_BIN}/Contents/MacOS/$f"
    fi
    llvm-cov report \
        "${COV_BIN}" \
        -instr-profile=.build/debug/codecov/default.profdata \
        -ignore-filename-regex=".build|Tests" \
        -use-color
fi

echo "► generating coverage..."

REGEX_LINES='"totals"\s*:\s*\{.*?"lines"\s*:\s*.*?"percent"\s*:([0-9\.]*)'
REGEX_FUNCTIONS='"totals"\s*:\s*\{.*?"functions"\s*:\s*.*?"percent"\s*:([0-9\.]*)'
REGEX_INSTANTIATIONS='"totals"\s*:\s*\{.*?"instantiations"\s*:\s*.*?"percent"\s*:([0-9\.]*)'
REGEX_REGIONS='"totals"\s*:\s*\{.*?"regions"\s*:\s*.*?"percent"\s*:([0-9\.]*)'
COVFILE=".build/debug/codecov/swift-httprequest.json"

PERCENT_LINES=`printf '%.2f' $(pcregrep -o1 "$REGEX_LINES" "$COVFILE")`
[ $? != 0 ] && exit 1
PERCENT_FUNCTIONS=`printf '%.2f' $(pcregrep -o1 "$REGEX_FUNCTIONS" "$COVFILE")`
[ $? != 0 ] && exit 1
PERCENT_INSTANTIATIONS=`printf '%.2f' $(pcregrep -o1 "$REGEX_INSTANTIATIONS" "$COVFILE")`
[ $? != 0 ] && exit 1
PERCENT_REGIONS=`printf '%.2f' $(pcregrep -o1 "$REGEX_REGIONS" "$COVFILE")`
[ $? != 0 ] && exit 1

echo "   ► totals:"
echo "      ★ instantiations: ${PERCENT_INSTANTIATIONS}%"
echo "      ★ functions: ${PERCENT_FUNCTIONS}%"
echo "      ★ lines: ${PERCENT_LINES}%"
echo "      ★ regions: ${PERCENT_REGIONS}%"

if [[ " $@ " =~ " +update_badge " ]]; then
    echo "► uploading badges:"
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
            x="2" 
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
            stroke="#FF1515"
            fill="#8c1515"
            style="
                stroke-width: 2;
                rx: 8;
                ry: 8;
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
            stroke="#0aff0a"
            fill="#0a700a"
            style="
                stroke-width: 2;
                rx: 8;
                ry: 8;
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
                font-size: 12pt;
                font-family: Menlo;
                text-anchor: middle;
            "
        >
        {{PERCENT}}%
        </text>
    </svg>
</svg>'
    
    PERCENTS=("${PERCENT_INSTANTIATIONS}" "${PERCENT_FUNCTIONS}" "${PERCENT_LINES}" "${PERCENT_REGIONS}")
    LABELS=("instantiations" "functions" "lines" "regions")
    GISTS=("91a7a42d5a8b205ed4d4da6553969aa7" "66bf591f9bf0903867893afad30b8b2c" "85d803a29268ce9ae5a6e59f3d8f7882" "ac14c03f4beef83001796db0c3a4c112")
    COVERAGE_GIST=coverage.gist
    for idx in {0..3}; do
        echo "   ► uploading badge for ${LABELS[$idx]}..."
        GIST_URL="git@gist.github.com:${GISTS[$idx]}.git"
        echo "      ► cloning gist ${GIST_URL} into ${COVERAGE_GIST}..."
        git clone "${GIST_URL}" "${COVERAGE_GIST}" > /dev/null 2> /dev/null
        [ $? != 0 ] && exit 1
        
        SVG="swift-httprequesting-${LABELS[$idx]}-coverage.svg"
        echo "      ► creating SVG ${SVG}..."
        
        SVG_PATH="${COVERAGE_GIST}/${SVG}"
        echo "$TMPL" | \
            sed 's/{{PERCENT}}/'"${PERCENTS[$idx]}"'/' | \
            sed 's/{{LABEL}}/'"$(tr '[:lower:]' '[:upper:]' <<< ${LABELS[$idx]:0:1})${LABELS[$idx]:1}"'/' > \
            "${SVG_PATH}"
        [ $? != 0 ] && rm -rf "${COVERAGE_GIST}" && exit 1
        echo "      ► created SVG: \"${SVG_PATH}\""

        echo "      ► push badge ${LABELS[$idx]}..."
        pushd "${COVERAGE_GIST}" > /dev/null
        [ $? != 0 ] && rm -rf "${COVERAGE_GIST}" && exit 1
        echo "      ► set commit \"coverage update: ${GIT_HASH}\""
        git commit -am "coverage update: ${GIT_HASH}" > /dev/null 2> /dev/null
        git push origin master > /dev/null 2> /dev/null
        popd > /dev/null
        [ $? != 0 ] && rm -rf "${COVERAGE_GIST}" && exit 1
        rm -rf "${COVERAGE_GIST}"
        echo "      ► clean up: ${COVERAGE_GIST}"
    done
fi
