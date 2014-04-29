#/bin/sh

for I in $(dirname "$0")/source/cassowary/*.d
do
	uncrustify -c "$(dirname "$0")/uncrustify.cfg" --no-backup "$I"
done
