#!/bin/bash

sum=0
numbers_passed=1
while true
do
    read -p "Enter num: " num
    sum=$((sum + num))
    average=$(echo "scale=2; $sum / $numbers_passed" | bc)
    numbers_passed=$((numbers_passed + 1))

    read -p "To exit type 'x'" choice
    if [ $choice == 'x' ]
    then
        break
    fi 
done
echo "The sum is $sum"
echo "The average is $average"

