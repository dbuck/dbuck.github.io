# Given the discord/midjourney image url, or a gallery link, download the image
# extract the job uuid from the url
# get the prompt and detils from the "api"
# download the image local add finally add the new image to the top of the gallery

# Usage: ./add_images.sh <discord midjourney image url>
# Example: ./add_images.sh https://cdn.discordapp.com/attachments/994749477233631273/1074171190173765652/vsai_Desiccated_mummified_autumnal_thorny_vine_dryad_marquis_de_272d88b3-b818-4800-be28-705c6b58e4a9.png
# Example: ./add_images.sh https://www.midjourney.com/app/jobs/a3c01f61-2eec-4577-a44c-2e8da7d4faf6/

# rip job id out of the urls... this is a bit of a hack
URL=$1
# remove trailing slash ffrom url, in case of MJ gallery page url in the format of https://www.midjourney.com/app/jobs/a3c01f61-2eec-4577-a44c-2e8da7d4faf6/
URL="${URL%/}"
# extract filename from url
FNAME="${URL##*/}"
# remove extension
FNAME="${FNAME%.*}"
# job uuid is everything after the last _ by mj's current conventions
JOB_ID="${FNAME##*_}"

echo "Job ID: $JOB_ID"

JOB_DATA=`curl -s 'https://www.midjourney.com/api/app/job-status/' \
  -H 'authority: www.midjourney.com' \
  -H 'accept: */*' \
  -H 'accept-language: en-US,en;q=0.9,und;q=0.8' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'dnt: 1' \
  -H 'origin: https://www.midjourney.com' \
  -H 'pragma: no-cache' \
  -H 'cookie: <GET COOKIE HEADER FROM NETWORK PANEL UNTIL THERE IS A WAY TO AUTH OFFICIALLY?>' \
  -H 'sec-ch-ua: "Not_A Brand";v="99", "Google Chrome";v="109", "Chromium";v="109"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-origin' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36' \
  --data-raw "{\"jobIds\":[\"$JOB_ID\"]}" \
  --compressed`

JOB_PROMPT=`echo $JOB_DATA | jq -r .full_command`
JOB_HEIGHT=`echo $JOB_DATA | jq -r .event.height`
JOB_WIDTH=`echo $JOB_DATA | jq -r .event.width`
JOB_GALLERY_ENTRY="{ id: \"$JOB_ID\", w: $JOB_WIDTH, h: $JOB_HEIGHT, prompt: \"$JOB_PROMPT\" },"

# https://stackoverflow.com/questions/39788145/inserting-spaces-before-the-word-while-adding-lines-using-sed :shrug:
# add the prompt to the gallery
echo "Adding prompt: $JOB_GALLERY_ENTRY"
awk -v JOB="$JOB_GALLERY_ENTRY" '/{{UNSHIFT_PROMPTS_HERE}}/ {$0=$0 ORS "    " JOB; }1' index.html > index.html.tmp && mv index.html.tmp index.html

JOB_IMAGE=`echo $JOB_DATA | jq -r .image_paths[0]`
ARCHIVE_FOLDER=jobs/$(date +%Y-%m)
mkdir -p $ARCHIVE_FOLDER
curl -s $JOB_IMAGE > $ARCHIVE_FOLDER/$JOB_ID.png
