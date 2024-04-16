from pyspark.sql import SparkSession
from pyspark.sql import types
from pyspark.sql.functions import to_date
import sys

# Transform column types
def df_spark_transform(df):
    # Transform string column to DoubleType
    df = df.withColumn("SS", df["SS"].cast("double"))
    
    # Transform string column to LongType
    df = df.withColumn("STAID", df["STAID"].cast("long"))
    df = df.withColumn("SOUID", df["SOUID"].cast("long"))
    df = df.withColumn("Q_SS", df["Q_SS"].cast("long"))
    
    # Transform string column to TimestampType
    df = df.withColumn("DATE", to_date("DATE", "yyyyMMdd"))
    
    return df

def process_files(input_directory, output_directory):
    spark = SparkSession.builder.appName("Process Text Files").getOrCreate()

    schema = types.StructType([
        types.StructField('STAID', types.StringType(), True),
        types.StructField('SOUID', types.StringType(), True),
        types.StructField('DATE', types.StringType(), True),
        types.StructField('SS', types.StringType(), True),
        types.StructField('Q_SS', types.StringType(), True)
    ])

    df  = spark.read \
        .option("header", "true") \
        .schema(schema) \
        .csv(input_directory)

    # Transform column types
    df = df_spark_transform(df)

    write_schema = types.StructType([
        types.StructField('STAID', types.LongType(), True),
        types.StructField('SOUID', types.LongType(), True),
        types.StructField('DATE', types.TimestampType(), True),
        types.StructField('SS', types.DoubleType(), True),
        types.StructField('Q_SS', types.LongType(), True)
    ])

    df \
        .write \
        .option("schema",write_schema) \
        .csv(f"{output_directory}/.csv", mode="overwrite", header=True)

    spark.stop()

if __name__ == "__main__":
    bucket_name = sys.argv[1]
    bucket_uri = f"gs://{bucket_name}"
    input_path = f"{bucket_uri}/raw"
    output_path = f"{bucket_uri}/spark"
    process_files(input_path, output_path)