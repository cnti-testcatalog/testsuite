 retry () {
TIME=0
EXIT=1
until [[ $EXIT -eq 0 ]]; do 
    eval $1
    EXIT=$?
    TIME=$(($TIME + 1))
    sleep 1
    if [[ $TIME -eq 10 ]]; then
        exit 1
    fi
done
}
