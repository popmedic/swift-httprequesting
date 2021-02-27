#!/bin/sh

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
REGEX_INSTANSIATIONS='"totals"\s*:\s*\{.*?"instantiations"\s*:\s*.*?"percent"\s*:([0-9\.]*)'
REGEX_REGIONS='"totals"\s*:\s*\{.*?"regions"\s*:\s*.*?"percent"\s*:([0-9\.]*)'
COVFILE=".build/debug/codecov/swift-httprequest.json"

PERCENT_LINES=`pcregrep -o1 "$REGEX_LINES" "$COVFILE" | cut -d'.' -f1`
PERCENT_FUNCTIONS=`pcregrep -o1 "$REGEX_FUNCTIONS" "$COVFILE" | cut -d'.' -f1`
PERCENT_INSTANSIATIONS=`pcregrep -o1 "$REGEX_INSTANSIATIONS" "$COVFILE" | cut -d'.' -f1`
PERCENT_REGIONS=`pcregrep -o1 "$REGEX_REGIONS" "$COVFILE" | cut -d'.' -f1`
[ $? != 0 ] && exit 1
echo "   ► totals:"
echo "     ★ instansiations: ${PERCENT_INSTANSIATIONS}%"
echo "     ★ functions: ${PERCENT_FUNCTIONS}%"
echo "     ★ lines: ${PERCENT_LINES}%"
echo "     ★ regions: ${PERCENT_REGIONS}%"

if [[ " $@ " =~ " +update_badge " ]]; then
    COVERAGE_GIST=coverage.gist
    echo "   ► cloning gist into ${COVERAGE_GIST}..."
    git clone git@gist.github.com:a555f644f50b16b6dd3a04a28af6f293.git "${COVERAGE_GIST}"
    [ $? != 0 ] && exit 1

    TMPL='<svg  xmlns="http://www.w3.org/2000/svg"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    width="128"
    height="24">
<rect 
    x="0" 
    y="0" 
    height="100%" 
    width="100%"
    stroke="#0a700a"
    fill="gray"
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
    stroke="#0a700a"
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
    style="
        fill: #FFFFFF; 
        font-size: 16;
        font-family: Arial;
        stroke: none; 
        text-anchor: middle;
    "
>
{{PERCENT}}%
</text>
</svg>'
    GIT_HASH=`git rev-parse --short HEAD`
    [ $? != 0 ] && rm -rf "${COVERAGE_GIST}" && exit 1
    echo "   ► current hash: ${GIT_HASH}"
    
    echo "   ► creating SVG..."
    echo "$TMPL" | sed 's/{{PERCENT}}/'"$PERCENT_LINES"'/' > "${COVERAGE_GIST}/swift-httprequesting-coverage.svg"
    [ $? != 0 ] && rm -rf "${COVERAGE_GIST}" && exit 1
    echo "   ► created SVG: \"${COVERAGE_GIST}/swift-httprequesting-coverage.svg\""

    echo "   ► push gist..."
    pushd "${COVERAGE_GIST}" > /dev/null
    [ $? != 0 ] && rm -rf "${COVERAGE_GIST}" && exit 1
    git commit -am "coverage update: ${GIT_HASH}"
    [ $? != 0 ] && popd > /dev/null && rm -rf "${COVERAGE_GIST}" && exit 1
    git push origin master
    [ $? != 0 ] && popd > /dev/null && rm -rf "${COVERAGE_GIST}" && exit 1
    popd > /dev/null
    [ $? != 0 ] && rm -rf "${COVERAGE_GIST}" && exit 1
    rm -rf "${COVERAGE_GIST}"
fi

echo "► coveraged generated"
