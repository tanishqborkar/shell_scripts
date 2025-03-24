#!/bin/bash

ans=0

read -p "Enter num1: " num1

while true
do
    
    
    echo "Choose an operation from this"
    echo "1) Add"
    echo "2) Subtract"
    echo "3) Multiply"
    echo "4) Divide"
    echo "5) Exponent"
    echo "6) Exit"

    read -p "Enter choice: " i

    if [ $i -eq 1 ]
    then
        read -p "Enter num2: " num2
        ans=$((num1 + num2))
        echo "Result: $ans"
    elif [ $i -eq 2 ]
    then
        read -p "Enter num2: " num2
        ans=$((num1 - num2))
        echo "Result: $ans"
    elif [ $i -eq 3 ]
    then
        read -p "Enter num2: " num2
        ans=$((num1 * num2))
        echo "Result: $ans"
    elif [ $i -eq 4 ]
    then
        if [ $num2 -eq 0 ]
        then
            echo "Division by zero error"
        else
            read -p "Enter num2: " num2
            ans=$(echo "scale=2; $num1 / $num2" | bc)
            echo "Result: $ans"
        fi
    elif [ $i -eq 5 ]
    then
        read -p "Enter num2: " num2
        ans=$((num1 ** num2))
        echo "Result: $ans"
    elif [ $i -eq 6 ]
    then
        break
    else
        echo "Invalid choice. Please try again."
    fi
    num1=$((ans))
done
