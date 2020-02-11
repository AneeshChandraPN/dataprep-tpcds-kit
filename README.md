Setup the tpcds toolkit on an EC2 instance
Mount a volume with atleast 20G to hold the datasets

```
sudo yum install gcc make flex bison byacc git
git clone https://github.com/gregrahn/tpcds-kit.git
cd tpcds-kit
sudo mkdir /data/tpcds
sudo chown ec2-user /data/tpcds
```

Export the environment variables with connection properties to the RDS instance

```
export MYSQL_HOST=emarket.xxxx.ap-southeast-1.rds.amazonaws.com
export MYSQL_PORT=3306
export MYSQL_USER=admin
export MYSQL_PASSWORD=xxxx
```

Setup the database 
Alter the tables in the database to include a create_dt and update_dt

```
mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD -e "drop database if exists emarket;"
mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD -e "create database emarket;"
mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD -D emarket < tools/tpcds.sql
mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD -D emarket < tools/tpcds_cdc_columns.sql
```

Prepare data to be loaded into MySQL database, with a scale factor of 10G

```
cd tools
make OS=LINUX
./dsdgen -SCALE 10 -f -DIR /data/tpcds/
```

Create a shell script to load the data into MySQL

```
rm -rf log_load_data.log
touch log_load_data.log
for file_name in `ls /data/tpcds/*.dat`; do
    table_file=$(echo "${file_name##*/}")
    table_name=$(echo "${table_file%.*}")
    load_data_sql="LOAD DATA LOCAL INFILE '$file_name' INTO TABLE $table_name FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n';"
    mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD --local-infile=1 -D emarket -e "$load_data_sql" >> log_load_data.log 2>&1 &
done
```


Update the table data with create and update timestamps

```
rm -rf post_log_load_data.log
touch post_log_load_data.log
for file_name in `ls /data/tpcds/*.dat`; do
    table_file=$(echo "${file_name##*/}")
    table_name=$(echo "${table_file%.*}")
    update_data_sql="UPDATE $table_name SET create_dt=CURRENT_TIMESTAMP WHERE create_dt='0000-00-00 00:00:00';"
    mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD --local-infile=1 -D emarket -e "$update_data_sql" >> post_log_load_data.log 2>&1 &
done
```
