#!/bin/bash -ex


application="${DISTELLI_APPNAME}"
environment="${DISTELLI_ENV}"
current_sha="${DISTELLI_RELREVISION:0:7}"
if [[ $API_TOKEN ]]; then
    api_token=${API_TOKEN}
else
    api_token=${DISTELLI_SECRET}
fi
api_token=${API_TOKEN:-}
github_link="https://github.com/ConsumerAffairs/${application}"
jira_link="https://consumeraffairs.atlassian.net/browse/"
webhook_link="$SLACK_URL"
run_mode="${1:-deploy-notes}"
slack_channel='#general'

if ! [[ "${DISTELLI_RELBRANCH}" == master ]]; then
    exit 0
fi

output="$(date): New deployment of ${application} into ${environment} environment just finished!\n\n"
output+="SHA: ${DISTELLI_RELREVISION:0:7}\n\n"

if [[ "${run_mode}" == release-notes ]]; then
    url="https://api.distelli.com/rtimoshenko/envs/${environment}/deployments?apiToken=${api_token}&max_results=1&order=desc"
    jq_pattern='.deployments[0].release_version'
else
    url="https://api.distelli.com/rtimoshenko/envs/${environment}/deployments?apiToken=${api_token}&max_results=2&order=desc"
    jq_pattern='.deployments[1].release_version, .deployments[0].release_version'
fi

releases=$(curl -s  ${url} | jq -r "${jq_pattern}")

if [[ "${run_mode}" == release-notes ]]; then
       sha_range+="${current_sha}"
fi

for release in $releases
do
    url="https://api.distelli.com/rtimoshenko/apps/${application}/releases/${release}?apiToken=${api_token}"
    sha=$(curl -s ${url} | jq -r ' .release.commit.commit_id')
    if ! [[ $sha_range ]]; then
        sha_range="${sha:0:7}"
    else
        sha_range+="...${sha:0:7}"
    fi
done

tickets=$(git log --pretty=oneline $sha_range \
    | sed -ne "s|.* \([A-Z]\{3,10\}-[A-Za-z0-9]\{1,4\}\).*|\1|p" \
    | sed -e "s~^~${jira_link}~" \
    | sort \
    | uniq)

output+="Diff: ${github_link}/compare/${sha_range}\n\n"
output+="Tickets:\n"
for ticket in tickets
do
    output+="$tickets\n"
done
output+="\n"
prs=$(git log --pretty=oneline $sha_range \
    | sed -ne 's|.* request \#\([0-9]\{3,3\}\) from.*|\1|p' \
    | sed -e "s~^~${github_link}/pull/~" \
    | sort \
    | uniq)

output+="PRs:\n"
for pr in $prs
do
    output+="$pr\n"
done

printf "${output}"

if [[ "${run_mode}" == release-notes ]]; then
    exit
fi

#report to Slack
curl -X POST --data-urlencode 'payload={
   "channel":"'"${slack_channel}"'",
   "username":"The Releaser",
   "text":"'"${output}"'",
   "icon_emoji":":distelli_is_awesome:"
}' ${webhook_link}
