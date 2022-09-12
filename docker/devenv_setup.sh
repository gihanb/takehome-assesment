export GREEN='\033[0;32m'
export RED=$'\e[0;31m'
#cd app_image
cp -r ../operations-task/rates .
docker system prune -f
docker image ls
#cd ..

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

cat ../operations-task/db/rates.sql > pg_init.sql

#cat rates.sql > pg_init.sql

#less rates.sql
docker-compose -f docker-compose-pg.yaml build
#docker-compose -f docker-compose-pg.yaml up
nohup docker-compose -f docker-compose-pg.yaml up &

sleep 5

echo "${GREEN} waiting DB to be responding"
until $(curl --output /dev/null --silent --head --fail http://0.0.0.0:3000); do
    printf '.'
    sleep 5
done


did_db=$(docker ps -q -f name=rate-db)

#docker exec -i $did_db pg_restore -c -h localhost -U postgres -d rates  rates.sql

echo -e "${GREEN} DB health Check"

docker exec $did_db psql -h localhost -U postgres -c "SELECT 'alive'"

echo "${GREEN} You are ready to go"
