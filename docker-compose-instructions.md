# Setup Instructions for IIIF Cloud using Docker compose

## Components

### Object Storage

IIIF Cloud uses S3 compatible storage to store images and PDFs. The system has been tested with AWS S3 but should also work with S3 compatible object storage systems as well.

### Cantaloupe S3 Server

The IIIF Cloud docker compose setup uses the [Cantaloupe IIIF Image Server](https://cantaloupe-project.github.io/). The docker image that is used is the [UCLA Library docker-cantaloupe distribution](https://github.com/UCLALibrary/docker-cantaloupe/tree/main).

### Redis

The IIIF Cloud system uses Redis as the job backend for the rails service. The docker compose system utilizes the [official image](https://hub.docker.com/_/redis).

### Postgres DB

The IIIF Cloud system uses Postgres as the DB for the CMS subsystem.  The docker compose system utilizes the [official image](https://hub.docker.com/_/postgres).

## Running the Docker Compose system

### 1. Set environment variables

Using the .env.example as a guide, set the appropriate values for the variables.

The sections below have some additional guidance in terms of proper setting of these variables.

### 2. Setup the S3 bucket

Whether using AWS S3 or a compatible service, create a bucket that will hold your uploaded images.

Set the ENV variable **AWS_BUCKET_NAME** to the name of the bucket.

Be sure to proved a access key and a secret access key which has access to this resource.  SET the appropriate values in the ENV variables **AWS_ACCESS_KEY_ID** and **AWS_SECRET_ACCESS_KEY**.

If using AWS S3, set the ENV variable **AWS_REGION** to the region in which the bucket was created (i.e. us-east-1).

### 3. Setup a DB Data Storage Volume

In order to persist your DB between restarts, it is recommended that you set a local file directory as the location for the DB data.  This could be local block storage or a mounted NFS drive. Set the ENV variable **DB_VOLUME** to this directory.

### 4. Run Docker Compose for the First Time

From the root of the project repo run:

~~~shell
docker compose up --build
~~~

This will build the iiif-cloud image and startup the entire system once built.

After the first run, if the code has not changed you can run:

~~~shell
docker compose up
~~~

### 5. Change the Admin Password of the IIIF Cloud CMS

The IIIF CMS is seeded with an initial admin account of:

~~~
Username: admin@example.com
Password: password
~~~

This should be immediately changed after first login. 

1. Navigate to the IIIF Cloud frontend and login using the credentials above.
2. Go to user management (the People Icon on the sidebar navigation)
3. Edit the Administrator user
4. Set the Email and Password to your desired values.



