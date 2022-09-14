export GREEN='\033[0;32m'
export RED=$'\e[0;31m'

## changing of db username or password


if [[ "$#" -eq 0 ]];then
        echo "{$GREEN} proceed with default setup"
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

# Cleaning up the environment

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

cp -r ../operations-task/rates .

cat ../operations-task/db/rates.sql > pg_init.sql

# For troubelshooting purpose comment the nohup and enable the general docker compose up

docker-compose -f docker-compose-pg.yaml build
#docker-compose -f docker-compose-pg.yaml up
nohup docker-compose -f docker-compose-pg.yaml up &

#Health Check

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
