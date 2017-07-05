#1/bin/sh

deletion_list="delete_from_chagas"

for model in `sort -R $deletion_list`; do
	rm -r --one-file-system --interactive=never $model
done
