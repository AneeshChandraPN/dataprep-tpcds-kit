rm -rf log_load_data.log
touch log_load_data.log
for file_name in `ls /data/tpcds/*.dat`; do
    table_file=$(echo "${file_name##*/}")
    table_name=$(echo "${table_file%.*}")
    load_data_sql="LOAD DATA LOCAL INFILE '$file_name' INTO TABLE $table_name FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n';"
    # echo $load_data_sql
    mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD --local-infile=1 -D emarket -e "$load_data_sql" >> log_load_data.log 2>&1 &
done
