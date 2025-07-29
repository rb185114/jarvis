#!/bin/bash
echo "#################################################################"
echo " Script Task: Scaling Down Pods, Flushing redis, Scaling Up Pods "
echo "#################################################################"
echo " "

scaleDown() {
    echo "Scaling DOWN all store and terminal01 Pods..."
    kubectl scale deployment -n store --all --replicas=0
    sleep 5
    numPodsLeft=$(kubectl get pods -n store | wc -l)
	echo "Total store pods to scale down - $numPodsLeft"
	while [ $numPodsLeft -gt 0 ]; do
		sleep 3
		numPodsLeft=$(kubectl get pods -n store | wc -l)
		echo -e "Please Wait. Scaling down remaining pods - $numPodsLeft"
	done
    echo " "
    kubectl scale deployment -n terminal01 --all --replicas=0
    sleep 5
    numPodsLeft=$(kubectl get pods -n terminal01 | wc -l)
	echo "Total terminal01 pods to scale down - $numPodsLeft"
	while [ $numPodsLeft -gt 0 ]; do
		sleep 3
		numPodsLeft=$(kubectl get pods -n terminal01 | wc -l)
		echo -e "Please Wait. Scaling down remaining pods - $numPodsLeft"
	done

    echo "Scaling Down All store and terminal01 Pods - Complete !!!"
    echo " "
}

flushRedisPod() {
    echo "Scaling Up Store Redis Pod..."
    redDeploy=$(kubectl get deployments -n store | grep -i redis | awk '{print $1}')
    kubectl scale deployment $redDeploy -n store --replicas=1
	sleep 5
    status=$(kubectl get deployment -n store | grep -i redis | awk '{print $2}')
    echo "Please wait. Redis Status is $status"
    declare i isReady=0
    while [ $isReady -eq "0" ]; do
        sleep 3
        status=$(kubectl get deployment -n store | grep -i redis | awk '{print $2}')
        echo "Please wait. Redis Status is $status"
        if [ $status = "1/1" ]
        then
            ((isReady++))
        fi
    done
    echo "Please wait. Redis Status is $status"
    echo "Redis pod ready !!!"
    echo " "
    echo "Flashing Store Redis Pod..."
    redPod=$(kubectl get pods -n store | grep -i redis | awk '{print $1}')
    kubectl exec -it $redPod -n store -- redis-cli -a redis@jarvis-sco flushAll
    echo "Flashing Redis Executed !!!"
    echo " "
}

scaleUp() {

    echo "Scaling UP all store and terminal01 Pods..."
    kubectl scale deployment -n store --all --replicas=1
    kubectl scale deployment -n terminal01 --all --replicas=1

    numPodsLeft=$(kubectl get pods -n store | grep "0/1" | wc -l)
    echo "Total Store pods to scale Up = $numPodsLeft"
    while [ $numPodsLeft -gt 0 ]; do
     	sleep 3
		numPodsLeft=$(kubectl get pods -n store | grep "0/1" | wc -l)
     	echo -e "Please Wait. Scaling Up remaining pods - $numPodsLeft"
    done
    echo " "


    numPodsLeft=$(kubectl get pods -n terminal01 | grep "0/1"| wc -l)
    echo "Total Terminal01 pods to scale Up - $numPodsLeft"
	while [ $numPodsLeft -gt 0 ]; do
		sleep 5
        	numPodsLeft=$(kubectl get pods -n terminal01 |grep "0/1" | wc -l)
		echo -e "Please Wait. Scaling Up remaining pods - $numPodsLeft"
	done
    echo "Scaling UP all store and terminal01 Pods - Complete !!!"
    echo " "
}


scaleDown
flushRedisPod
scaleUp

echo "Task Complete."
#EndOfScript-RB185114
