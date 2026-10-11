.PHONY: setup data build docs clean tf-plan

setup:            ## install Python dependencies
	pip install -r requirements.txt

data:             ## generate the synthetic dataset into dbt/seeds
	python data_generator/generate.py --out dbt/seeds

build: data       ## run seeds, models and tests on DuckDB
	cd dbt && DBT_PROFILES_DIR=. dbt build

docs:             ## build and serve dbt docs (lineage graph)
	cd dbt && DBT_PROFILES_DIR=. dbt docs generate && DBT_PROFILES_DIR=. dbt docs serve

prod:             ## run against BigQuery (needs GCP_PROJECT_ID and gcloud auth)
	cd dbt && DBT_PROFILES_DIR=. DBT_TARGET=prod dbt build

tf-plan:          ## preview the GCP resources
	cd terraform && terraform init && terraform plan

clean:
	rm -rf dbt/target dbt/logs dbt/*.duckdb dbt/seeds/*.csv
