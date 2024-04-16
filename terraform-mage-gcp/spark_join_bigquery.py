from pyspark.sql import SparkSession
from pyspark.sql import types
import sys

def process_files(input_directory1, input_directory2, output_directory1, output_directory2, temp_bucket_name):
    spark = SparkSession.builder.appName("Process Text Files").getOrCreate()

    spark.conf.set('temporaryGcsBucket', temp_bucket_name)

    schema1 = types.StructType([
        types.StructField('STAID', types.LongType(), True), 
        types.StructField('CN', types.StringType(), True)
    ])

    schema2 = types.StructType([
        types.StructField('STAID', types.LongType(), True),
        types.StructField('SOUID', types.LongType(), True),
        types.StructField('DATE', types.TimestampType(), True),
        types.StructField('SS', types.DoubleType(), True),
        types.StructField('Q_SS', types.LongType(), True)
    ])

    df_source  = spark.read \
            .schema(schema1) \
            .csv(input_directory1)

    df_source.createOrReplaceTempView('df_dimensions')


    df_spark  = spark.read \
            .schema(schema2) \
            .csv(input_directory2)

    df_spark.createOrReplaceTempView('df_metrics')

    df_join = spark.sql("""
    SELECT 
    m.STAID AS Station_id,
    d.CN AS Country_code,
    m.DATE,
    SUM(m.SS) AS Sun_hrs,
    m.Q_SS AS Data_quality
    FROM
        df_metrics m
    LEFT JOIN
        df_dimensions d ON m.STAID = d.STAID
    WHERE
        m.Q_SS = 0
    GROUP BY
        m.STAID,
        d.CN,
        m.DATE,
        m.Q_SS
    """)

    df_join.write.mode("overwrite") \
    .format('bigquery') \
    .option('table', output_directory2) \
    .save()

    spark.stop()

if __name__ == "__main__":
    bucket_name = sys.argv[1]
    temp_bucket_name = sys.argv[2]
    project_id = sys.argv[3]
    bucket_uri = f"gs://{bucket_name}"

    input_path1 = f"{bucket_uri}/spark_sources/**/*.csv"
    input_path2 = f"{bucket_uri}/spark/**/*.csv"
    output_path1 = f"{bucket_uri}/report"
    output_path2 = f"{project_id}.sunshine_eu_dataset.report"
    process_files(input_path1, input_path2, output_path1, output_path2, temp_bucket_name)