#!/bin/bash

path="$(pwd)"

isSyncDone="false"
function clacSyncDone {
	currentBlock="$(docker exec clientCible /tmp/geth attach ipc:/root/.ethereum/geth.ipc --exec eth.syncing.currentBlock)"
	highestBlock="$(docker exec clientCible /tmp/geth attach ipc:/root/.ethereum/geth.ipc --exec eth.syncing.highestBlock)"
	if [ $(expr $highestBlock - $currentBlock) -lt 100 ]
	then
		isSyncDone="true"
	fi
}

function getNetworkDatas {
	for i in {6061..6076}
	do
		curl -s "http://127.0.0.1:$i/debug/metrics" >> "client$i.json"
	done
}

docker-compose up -d

# on attend 5 min pour la mise en route du miner
echo "5 min d'attente pour l'initialisation du réseau"
sleep 120
echo "fin de l'initialisation du réseau"

# Exp sync Snap
#typeSync="Snap"
# Exp sync DHT
#typeSync="Dht"
# Exp sync Snap avec syncDHT
typeSync="SnapSyncDHT"
# Exp sync DHT avec avec syncDHT
#typeSync="DhtSyncDHT"

mkdir "$path/Résultat$typeSync"
mkdir "$path/Résultat$typeSync/metrics0"
cd "$path/Résultat$typeSync/metrics0"

echo "Récupération des données avant nouveau pair"
getNetworkDatas

echo "Lancement nouveau pair"

# démarrer le noeud cible : sync Snap
#docker run -d --name clientCible --network=expfullnode_priv-eth-net-clientDHT -p 6059:6059 -p 30209:30209 gethsansdata:latest --bootnodes="enode://af22c29c316ad069cf48a09a4ad5cf04a251b411e45098888d114c6dd7f489a13786620d5953738762afa13711d4ffb3b19aa5de772d8af72f851f7e9c5b164a@172.16.238.2:30301" --networkid=1214 --v5disc --kBucket=4 --metrics --metrics.expensive --metrics.addr="0.0.0.0" -port 30209 --metrics.port 6059 --nodekeyhex="e70c3d16cfeb9248407c50124b221d649c6a87392de266accfe8915c264d5729"

# démarrer le noeud cible : sync DHT
#docker run -d --name clientCible --network=expfullnode_priv-eth-net-clientDHT -p 6059:6059 -p 30209:30209 gethsansdata:latest --bootnodes="enode://af22c29c316ad069cf48a09a4ad5cf04a251b411e45098888d114c6dd7f489a13786620d5953738762afa13711d4ffb3b19aa5de772d8af72f851f7e9c5b164a@172.16.238.2:30301" --networkid=1214 --v5disc --kBucket=4 --metrics --metrics.expensive --metrics.addr="0.0.0.0" -port 30209 --metrics.port 6059 -dht -commonBits=4 --nodekeyhex="e70c3d16cfeb9248407c50124b221d649c6a87392de266accfe8915c264d5729"

# démarrer le noeud cible : sync Snap SyncDHT
docker run -d --name clientCible --network=expdhtnode_priv-eth-net-clientDHT -p 6059:6059 -p 30209:30209 gethsansdata:latest --bootnodes="enode://af22c29c316ad069cf48a09a4ad5cf04a251b411e45098888d114c6dd7f489a13786620d5953738762afa13711d4ffb3b19aa5de772d8af72f851f7e9c5b164a@172.16.238.2:30301" --networkid=1214 --v5disc --kBucket=4 --metrics --metrics.expensive --metrics.addr="0.0.0.0" -port 30209 --metrics.port 6059 -dhtSync -commonBits=4 --nodekeyhex="e70c3d16cfeb9248407c50124b221d649c6a87392de266accfe8915c264d5729"

# démarrer le noeud cible : sync DHT SyncDHT
#docker run -d --name clientCible --network=expdhtnode_priv-eth-net-clientDHT -p 6059:6059 -p 30209:30209 gethsansdata:latest --bootnodes="enode://af22c29c316ad069cf48a09a4ad5cf04a251b411e45098888d114c6dd7f489a13786620d5953738762afa13711d4ffb3b19aa5de772d8af72f851f7e9c5b164a@172.16.238.2:30301" --networkid=1214 --v5disc --kBucket=4 --metrics --metrics.expensive --metrics.addr="0.0.0.0" -port 30209 --metrics.port 6059 -dht -commonBits=4 -dhtSync --nodekeyhex="e70c3d16cfeb9248407c50124b221d649c6a87392de266accfe8915c264d5729"

echo "Début relevé de donnée"

y=1
while [ "$isSyncDone" != true ]
do 
	echo "$y"
	mkdir "$path/Résultat$typeSync/metrics$y"
	cd "$path/Résultat$typeSync/metrics$y"
	getNetworkDatas
	curl -s http://127.0.0.1:6059/debug/metrics >> clientCible.json
	let "y+=1"
	clacSyncDone
done

#pour la fin
echo "Relevé de données une fois le client sync"
mkdir "$path/Résultat$typeSync/metrics$y"
sleep 10
cd "$path/Résultat$typeSync/metrics$y"
curl -s http://127.0.0.1:6059/debug/metrics >> clientCible.json
getNetworkDatas
echo "Fin relevé de donnée"

#Récupération des .ethereum
echo "Récupération des .ethereum"
mkdir "$path/Résultat$typeSync/.ethereums"

mkdir "$path/Résultat$typeSync/.ethereums/clientCible"
docker cp clientCible:/root/.ethereum "$path/Résultat$typeSync/.ethereums/clientCible"

for i in {1..15}
do
	mkdir "$path/Résultat$typeSync/.ethereums/$i"
	echo "copie $i"
	docker cp expfullnode_bis-"$i"_1:/root/.ethereum $path/Résultat$typeSync/.ethereums/$i
done
mkdir "$path/Résultat$typeSync/.ethereums/16"
docker cp expfullnode_miner_1:/root/.ethereum "$path/Résultat$typeSync/.ethereums/16"

#calcul des db inspect
echo "calcul des db inspect"
mkdir "$path/Résultat$typeSync/db_inspect"
cd "$path/Résultat$typeSync/.ethereums/"
for i in *
do
	echo "db_inspect $i"
	$($path/../geth --datadir $path/Résultat$typeSync/.ethereums/$i/.ethereum db inspect >> $path/Résultat$typeSync/db_inspect/$i)
done

echo "Suppression de l'environement de test"
docker stop clientCible
docker rm clientCible
docker-compose down
