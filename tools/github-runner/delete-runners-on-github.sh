####
# Requirements:
#   Install "jq" to work with json in the shell
#
# USAGE:
#   GH_USER=TODO GH_TOKEN=TODO bash tools/github-runner/delete-runners-on-github.sh
#
# NOTES:
# For now, this script only deletes the first 100 runners. To delete more runners, run the script again.
#

curl -u $GH_USER:$GH_TOKEN -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/cncf/cnf-testsuite/actions/runners?per_page=100 | \
jq -r '.runners[].id' | \
while IFS='' read -r line; do
  echo "Calling url https://api.github.com/repos/cncf/cnf-testsuite/actions/runners/$line"
  curl -X DELETE -u $GH_USER:$GH_TOKEN -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/cncf/cnf-testsuite/actions/runners/$line"
done
