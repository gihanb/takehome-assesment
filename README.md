# Dev Environment setting up

<h3>Intro</h3>

The motivation behind implementing this solution is to create a simple way to deploy the application for the development team.

With the above note, this repository facilitates you to deploy the testable application without having much of a hassle with technologies. Hence this solution used most known softwares to deploy these two components with ease. All you need to have is docker, psql (client is enough) and curl. Mostly these tools may already be available in your machine.

Solution implemented using docker compose and bash scripts. compose consists of two services called api and db.

<h3> Prerequisites </h3>
 
 <ol>
  <li>Docker + docker compose</li>
  <li>curl and psql </li>
  <li>Anywhere you can run a bash script </li>
</ol>

Once you have confirmed all required softwares in your machine or your selected instance.

All you have to do is,

 <ol>
  <li>Go inside the docker folder and looks for "devenv_setup.sh" </li>
  <li>Then run that script ./devenv_setup.sh </li>
</ol>

```
takehome-assesment % ls
README.md	docker		operations-task
takehome-assesment % cd docker 
docker % ./devenv_setup.sh 
```
Once you run the script. It will run the docker compose and will deploy the application.

Note -: If you are a first time runner and the question asked at the mid of the script you can go with either option. Since still there are no db volumes created.
But from the second time you choose based on your requirement.

eg -: Let's say you have new rates.sql file to load. Then you have to remove the existing db volumes.

```
 Do you need the old db volumes to be stay ?  y or n 
n
```

That's all for the basic run...

The script will check the application status and exit when only it's healthy. So once script ran you will have the complete environment.

Generally you are free to do any change related to code change or data related change.

Please make sure not to change file names. Since bash script is sensitive to file name or file location changes.


<h3> Customizations Available </h3>

You can define database username and passwords as you like via command line parameters and default username and password are on the application configuration file.

1st argument will be username and second argument will be the password

```
takehome-assesment % ./devenv_setup.sh foo bar

{} database username and password will change,Note:order needs to be correct 
foo
bar
```

When you pass username and password. It will update following two locations.

```
takehome-assesment % cat operations-task/rates/config.py
DB = {
    "host": "db",
    "user": "foo",
    "password": "bar",
    "port": "5432"
}
takehome-assesment % cat docker/.env
POSTGRES_USER=foo
POSTGRES_PASSWORD=bar
DB_HOST=localhost

```


Here both application configuration and docker environment files will change. At the moment both host and port are not available for change via command line arguments.

host -: Docker compose template service value and mostly it's static

port -: port can be included into command line arguments but it's a 5432.It is a general port for postgres.

<h3> Tested Environments </h3>

Script is tested on both Mac and Ubuntu Machine so far.

Following section will briefly describe more about the script and what commands will run behind it. Those will not be mandatory to know for application deployment but for awareness purposes.

<h3> Let's find out what ./devenv_setup.sh will do behind the scenes </h3>


<h4> 1st section </h4>

First section will identify the commondline arguments and do the changes on configurations file with provided values.

```
## changing of db username or password


if [[ "$#" -eq 0 ]];then
        echo "{$GREEN} proceed with default settings"
elif [[ "$#" -eq 2 ]]; then
        echo "{$RED} database username and password will change,Note:order needs to be correct "
        username=$1
        password=$2
        echo $username
        echo $password
        sed -i -e '/"user":/ s/: .*/: "'$username'",/' ../operations-task/rates/config.py
        sed -i -e '/"password":/ s/: .*/: "'$password'",/' ../operations-task/rates/config.py
        sed -i -e '/POSTGRES_USER=/ s/=.*/='$username'/' .env
        sed -i -e '/POSTGRES_PASSWORD=/ s/=.*/='$password'/' .env
else
        echo "{$RED} wrong argument passing, please read the instructions. Default workflow will proceed"
fi

####
```
<h4> 2nd section </h4>

Clean up of the system. Before application deployment.

it will cleanup the unused images and will perform the docker volume removal related to the database and services down. This will make sure your application wont run with old data unless you required it.

```

docker system prune -f
docker image ls


echo " ${RED}Do you need the old db volumes to be stay ?  y or n "
read VAR


if [ "$VAR" = y ]; then
    echo "initialization script will not run"
    docker-compose -f docker-compose-pg.yaml down
elif [ "$VAR" = n ]; then
    docker-compose -f docker-compose-pg.yaml down --volumes
    docker volume prune -f
else
    echo "Not a valid answer."
    exit 1
fi
```

<h4> 3rd section </h4>

Here it will copy the application code to build folder and sametime database dump will copy to the the init script for database initialization. 

Important note to notify, if there is something not working or application node will not up. Here is a option you to see the console log. By uncommenting the following line. 

```
#docker-compose -f docker-compose-pg.yaml up
```



```
cp -r ../operations-task/rates .

cat ../operations-task/db/rates.sql > pg_init.sql


docker-compose -f docker-compose-pg.yaml build
#docker-compose -f docker-compose-pg.yaml up
nohup docker-compose -f docker-compose-pg.yaml up &
```

<h4> 4th section </h4>

Last section is mostly dedicated for monitoring and make sure application is running properly.

Mainly it will wait untill application to be respond and then it will check the database by exicuting a query. 

```
sleep 5
# waiting for application to be respond

echo "${GREEN} waiting DB to be responding"

until $(curl --output /dev/null --silent --head --fail http://0.0.0.0:3000); do
    printf '.'
    sleep 5
done


did_db=$(docker ps -q -f name=rate-db)


echo "${GREEN} DB health Check"

dbuser=$(head -n 1 .env | cut -d "=" -f 2)

docker exec $did_db psql -h localhost -U $dbuser -c "SELECT 'alive'"


echo "${GREEN} You are ready to go"
```


