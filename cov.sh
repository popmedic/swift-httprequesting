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
REGEX_INSTANTIATIONS='"totals"\s*:\s*\{.*?"instantiations"\s*:\s*.*?"percent"\s*:([0-9\.]*)'
REGEX_REGIONS='"totals"\s*:\s*\{.*?"regions"\s*:\s*.*?"percent"\s*:([0-9\.]*)'
COVFILE=".build/debug/codecov/swift-httprequest.json"

PERCENT_LINES=`pcregrep -o1 "$REGEX_LINES" "$COVFILE" | cut -d'.' -f1`
[ $? != 0 ] && exit 1
PERCENT_FUNCTIONS=`pcregrep -o1 "$REGEX_FUNCTIONS" "$COVFILE" | cut -d'.' -f1`
[ $? != 0 ] && exit 1
PERCENT_INSTANTIATIONS=`pcregrep -o1 "$REGEX_INSTANTIATIONS" "$COVFILE" | cut -d'.' -f1`
[ $? != 0 ] && exit 1
PERCENT_REGIONS=`pcregrep -o1 "$REGEX_REGIONS" "$COVFILE" | cut -d'.' -f1`
[ $? != 0 ] && exit 1
echo "   ► totals:"
echo "     ★ instantiations: ${PERCENT_INSTANTIATIONS}%"
echo "     ★ functions: ${PERCENT_FUNCTIONS}%"
echo "     ★ lines: ${PERCENT_LINES}%"
echo "     ★ regions: ${PERCENT_REGIONS}%"

if [[ " $@ " =~ " +update_badge " ]]; then
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
    
    PERCENTS=("${PERCENT_INSTANTIATIONS}" "${PERCENT_FUNCTIONS}" "${PERCENT_LINES}" "${PERCENT_REGIONS}")
    LABELS=("instantiations" "functions" "lines" "regions")
    GISTS=("91a7a42d5a8b205ed4d4da6553969aa7" "66bf591f9bf0903867893afad30b8b2c" "85d803a29268ce9ae5a6e59f3d8f7882" "ac14c03f4beef83001796db0c3a4c112")
    COVERAGE_GIST=coverage.gist
    for idx in 0 1 2 3; do
        GIST_URL="git@gist.github.com:${GISTS[$idx]}.git"
        echo "   ► cloning gist ${GIST_URL} into ${COVERAGE_GIST}..."
        git clone "${GIST_URL}" "${COVERAGE_GIST}"
        [ $? != 0 ] && exit 1
        
        SVG="swift-httprequesting-${LABELS[$idx]}-coverage.svg"
        echo "   ► creating SVG ${SVG}..."
        
        SVG_PATH="${COVERAGE_GIST}/${SVG}"
        echo "$TMPL" | sed 's/{{PERCENT}}/'"${PERCENTS[$idx]}"'/' > "${SVG_PATH}"
        [ $? != 0 ] && rm -rf "${COVERAGE_GIST}" && exit 1
        echo "   ► created SVG: \"${SVG_PATH}\""

        echo "   ► push gist..."
        pushd "${COVERAGE_GIST}" > /dev/null
        [ $? != 0 ] && rm -rf "${COVERAGE_GIST}" && exit 1
        git commit -am "coverage update: ${GIT_HASH}"
        git push origin master
        popd > /dev/null
        [ $? != 0 ] && rm -rf "${COVERAGE_GIST}" && exit 1
        rm -rf "${COVERAGE_GIST}"
    done
fi

echo "► coveraged generated"
