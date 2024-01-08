""" Generate a JSON index of Dropbox download links

Requires a private token in the file config/dropbox-token.txt (not included in the git repo)

Usage:

  $ cat config/dropbox-token.txt | python3 make-download-index.py > html/download-links.json

"""

import dropbox, json, re, sys

if len(sys.argv) != 3:
    print("Usage: python3 {} CONFIG.json LINKS_OUTPUT.txt", file=sys.stderr)
    exit(2)

config_file = sys.argv[1]
links_file = sys.argv[2]

with open(config_file, 'r') as input:
    config = json.load(input)

dbx = dropbox.Dropbox(config["token"])

# list all the files in the /Downloads director
listing = dbx.files_list_folder("/Downloads")

downloads = {}

# iterate over all files that match the pattern
for entry in sorted(listing.entries, key=lambda entry: entry.name):

    if isinstance(entry, dropbox.files.FileMetadata):
        result = re.match('^fgfs-americas-scenery-([ew]\d{3}[ns]\d{2})-(\d{8}).tar$', entry.name)
        if result:

            # extract fields from the filename
            bucket = result.group(1)
            date = result.group(2)

            # get existing shared link or create a new one
            sharing = dbx.sharing_create_shared_link("/Downloads/{}".format(entry.name))

            url = sharing.url

            if ("?" in url):
                url = url.replace('?dl=0', '?dl=1')
            else:
                url = url + "?dl=1"

            # add the new entry
            downloads[bucket] = {
                "name": entry.name,
                "date": date,
                "url": url,
                "size": entry.size,
            }

# Save the output as JSON
print(json.dumps(downloads, indent=2))

with open(links_file, 'w') as output:
    for bucket in downloads:
        print(downloads[bucket]['url'], file=output)


exit()
