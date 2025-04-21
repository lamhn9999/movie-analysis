# processing
mkdir backup
cp movie_dataset.csv backup_dataset.csv
mv backup_dataset.csv backup
export LC_NUMERIC=en_US.UTF-8 #IMPORTANT
cat movie_dataset.csv | head -n 1 > header.csv
awk 'BEGIN { ORS=""; inside=0 }
{
    if (inside) {
        printf "\\n%s", $0;
    } else {
        printf "%s", $0;
    }

    if (gsub(/"/, "&") % 2 == 1) {
        if (inside == 0) {
            inside = 1;
        } else {
            inside = 0;
            print "\n";
        }
    } else if (!inside) {
        print "\n";
    }
}' movie_dataset.csv > main_dataset.csv
cat main_dataset.csv | awk -F'"' 'BEGIN {ORS="";}
{
    if(NF == 0) printf("%s\n", $0);
    for (i=1; i<=NF; i++)
    {
        if(i % 2 == 0)
        {
            gsub(/,/, "~", $i);
            printf("%s", $i);
        }
        else printf("%s", $i);
    }
    printf("\n");
}
' > temp_dataset.csv
awk -F',' 'BEGIN {OFS = ","} {
    gsub(/^[ \t]+|[ \t]+$/, "", $7);
    gsub(/^[ \t]+|[ \t]+$/, "", $9);
    gsub(/^[ \t]+|[ \t]+$/, "", $14);
    print $0;
}' temp_dataset.csv > main_dataset.csv

#above 7.5
echo "id,original_title,vote_average" > rated_abv_dataset.csv
cat main_dataset.csv | tail -n +2 |awk -F',' 'BEGIN {ORS="";}
{
    if($18 >= 7.5) printf("%s,%s,%s\n", $1, $6, $18);
}
'| sort -gr -k3,3 -t"," >> rated_abv_dataset.csv

#lowest rev (zero $)
echo "original_title,revenue" > zero_revenue.csv
min_rev=$(cat main_dataset.csv | tail -n +2 | awk -F',' '{print $5}' | sort -g | head -n 1)
cat main_dataset.csv | tail -n +2 | awk -v cmp="$min_rev" -F',' 'BEGIN {OFS="\n";}
{
    if($5 == cmp) print($6","$5);
}' >> zero_revenue.csv

#top 10 rev
echo "id,original_title,revenue" > top_ten_revenue.csv
cat main_dataset.csv | tail -n +2 | awk -F',' '{print $1","$6","$5}' | sort -gr -t',' -k3,3 | head -n 10 >> top_ten_revenue.csv

#total movie asc
echo "director,total_movies" > sorted_total_movies_director.csv
cat main_dataset.csv | tail -n +2 | awk -F',' 'BEGIN {OFS="\n"} {
    print $9
}' | awk -F'|' 'BEGIN{OFS="\n"} {
    for(i=1; i<=NF; i++) print($i)
}' | sort | awk '{print ","$0}' | uniq -c | awk -F','  '{gsub(/[ \t]/, "", $1); print $2","$1}' | sort -gr -t',' -k2,2 >> sorted_total_movies_director.csv

echo "actor,total_movies" > sorted_total_movies_actor.csv
cat main_dataset.csv | tail -n +2 | awk -F',' 'BEGIN {OFS="\n"} {
    print $7
}' | awk -F'|' 'BEGIN{OFS="\n"} {
    for(i=1; i<=NF; i++) print($i)
}' | sort | awk '{print ","$0}' | uniq -c | awk -F','  '{gsub(/[ \t]/, "", $1); print $2","$1}' | sort -gr -t',' -k2,2 >> sorted_total_movies_actor.csv
echo "genre,total_movies" > sorted_total_movies_genre.csv
cat main_dataset.csv | tail -n +2 | awk -F',' 'BEGIN {OFS="\n"} {
    print $14
}' | awk -F'|' 'BEGIN{OFS="\n"} {
    for(i=1; i<=NF; i++) print($i)
}' | sort | awk '{print ","$0}' | uniq -c | awk -F','  '{gsub(/[ \t]/, "", $1); print $2","$1}' | sort -gr -t',' -k2,2 >> sorted_total_movies_genre.csv

#single_output
echo -n "" > single_output.txt
cat main_dataset.csv | tail -n +2 |awk -v sum_rev=0 -F ',' 'BEGIN {}
{
    sum_rev += $5 + 0;
} END {print("Total revenue of all movies: "sum_rev"$")}' >> single_output.txt
echo "Movie(s) with the highest revenue:" >> single_output.txt
max_rev=$(cat main_dataset.csv | tail -n +2 | awk -F',' '{print $5}' | sort -gr | head -n 1)
cat main_dataset.csv | tail -n +2 | awk -v cmp="$max_rev" -F',' 'BEGIN {OFS="\n";}
{
    if($5 == cmp) print($6" "$5);
}' >> single_output.txt
echo "Director(s) with the most movies:" >> single_output.txt
cat sorted_total_movies_director.csv | tail -n +2 | awk -F',' '{if(NR == 1) cmp=$2; if($2 == cmp) print $0; else exit;}' >> single_output.txt
echo "Actor(s) with the most movies:" >> single_output.txt
cat sorted_total_movies_actor.csv | tail -n +2 | awk -F',' '{if(NR == 1) cmp=$2; if($2 == cmp) print $0; else exit;}' >> single_output.txt

# release date asc
cat header.csv > sorted_release_date.csv
cat main_dataset.csv | tail -n +2 | rev | awk -F',' 'BEGIN {OFS="";}
{
    split($6, ydm, "/");

    if(length(ydm[3]) == 1) ydm[3] = ydm[3] "0";
    if(length(ydm[2]) == 1) ydm[2] = ydm[2] "0";
    rev_y = "";
    rev_m = "";
    rev_d = "";
    for(i = length($3); i > 0; i--) {
        rev_y = rev_y substr($3, i, 1);
    }
    for(i = length(ydm[3]); i > 0; i--) {
        rev_m = rev_m substr(ydm[3], i, 1);
    }
    for(i = length(ydm[2]); i > 0; i--) {
        rev_d = rev_d substr(ydm[2], i, 1);
    }
    printf("%s/%s/%s,%s\n", rev_y, rev_m, rev_d, substr($0, length($1)+2));
}' | sort -t',' -k1,1 | cut -c 12- | rev >> sorted_release_date.csv
