#/bin/sh

for I in $(dirname "$0")/source/cassowary/*.d
do
	uncrustify -c "$(dirname "$0")/uncrustify.cfg" --no-backup "$I"
done

# For some reason uncrustify drops the +x flag on d.d. Restore it here.
chmod +x "$(dirname "$0")/source/cassowary/d.d"
