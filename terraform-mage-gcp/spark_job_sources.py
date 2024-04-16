from pyspark.sql import SparkSession
from pyspark.sql import types
from pyspark.sql.functions import to_date
import sys

def process_files(input_directory, output_directory):
    spark = SparkSession.builder.appName("Process Text Files").getOrCreate()

    schema = types.StructType([
        types.StructField('STAID', types.LongType(), True), 
        types.StructField('SOUID', types.LongType(), True), 
        types.StructField('SOUNAME', types.StringType(), True), 
        types.StructField('CN', types.StringType(), True), 
        types.StructField('LAT', types.StringType(), True), 
        types.StructField('LON', types.StringType(), True), 
        types.StructField('HGHT', types.LongType(), True), 
        types.StructField('ELEI', types.StringType(), True), 
        types.StructField('START', types.StringType(), True), 
        types.StructField('STOP', types.StringType(), True), 
        types.StructField('PARID', types.StringType(), True), 
        types.StructField('PARNAME', types.StringType(), True)
    ])

    df_source  = spark.read \
        .option("header", "true") \
        .schema(schema) \
        .csv(input_directory, inferSchema=True)

    # Transform string column to LongType
    df_source = df_source.withColumn("STAID", df_source["STAID"].cast("long"))

    columns_to_keep = ['STAID','CN']  # List of columns to keep

    # Create a copy of the DataFrame with only the selected columns
    df_source = df_source.select(columns_to_keep)


    write_schema = types.StructType([
        types.StructField('STAID', types.LongType(), True), 
        types.StructField('CN', types.StringType(), True), 
    ])

    df_source \
        .write \
        .option("schema",write_schema) \
        .csv(f"{output_directory}/sources.csv", mode="overwrite", header=True)

    spark.stop()

if __name__ == "__main__":
    bucket_name = sys.argv[1]
    bucket_uri = f"gs://{bucket_name}"
    process_files(f"{bucket_uri}/sources", f"{bucket_uri}/spark_sources")