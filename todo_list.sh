#!/bin/bash

task_id=0  # Global task ID counter
tasks=()   # Array to store tasks

add_task() {
    local task="$1"
    local priority="medium"

    case "$2" in
        --high) priority="high" ;;
        --medium) priority="medium" ;;
        --low) priority="low" ;;
    esac

    task_id=$((task_id + 1))  # Increment task ID
    tasks+=("$task_id:$task:$priority")  # Store task in format "ID:Task:Priority"
    echo "Task added: '$task' (Priority: $priority) [ID: $task_id]"
}


list_tasks() {
    if [[ ${#tasks[@]} -eq 0 ]]; then
        echo "No tasks available"
        return
    fi

    echo "To-do List"
    for task in "${tasks[@]}"; do
        priority="${task##*:}"
        id_and_task="${task%:*}"
        exact_task="${id_and_task##*:}"
        exact_id="${id_and_task%%:*}"
        echo "[ID: $exact_id] (Task : $exact_task) (Priority: $priority) "
    done
}

remove_task() {
    local id_to_remove="$1"

    for i in "${!tasks[@]}"; do
        task_id="${tasks[i]%%:*}"

        if [[ "$task_id" == "$id_to_remove" ]]; then
            echo "Task removed: ${tasks[i]}"
            unset "tasks[i]"
            
            return
        fi
    done

    echo "Task ID $id_to_remove not found."
}

sort_tasks() {
    local n=${#tasks[@]}

    for ((i = 0; i < n - 1; i++)); do
        for ((j = 0; j < n - i - 1; j++)); do

            local task1="${tasks[j]}"
            local task2="${tasks[j+1]}"
            local p1="${task1##*:}"
            local p2="${task2##*:}"

            if [[ $(priority_rank "$p1") -lt $(priority_rank "$p2") ]]; then
                temp="${tasks[j]}"
                tasks[j]="${tasks[j+1]}"
                tasks[j+1]="$temp"
            fi
        done
    done

    echo "Tasks Sorted"

}

priority_rank() {
    case "$1" in 
        high) echo 3 ;;
        medium) echo 2 ;;
        low) echo 1 ;;
        *) echo 0 ;;
    esac
}

update_task() {
    local update_task_id="$1"
    local found=0  # Flag to check if task is found

    for i in "${!tasks[@]}"; do   # Iterate with index
        task="${tasks[i]}"
        task_id="${task%%:*}"

        if [[ "$task_id" == "$update_task_id" ]]; then  
            found=1  # Task found, set flag

            echo "Choose what you want to update"
            echo "1: Task"
            echo "2: Priority"
            echo "3: Both"

            read -p "Enter your choice: " choice

            if [[ $choice == 1 ]]; then
                read -p "Enter updated task: " new_task
                id="$(echo "$task" | cut -d':' -f1)"
                priority="$(echo "$task" | cut -d':' -f3)"
                tasks[i]="$id:$new_task:$priority"   # Update array
            
            elif [[ $choice == 2 ]]; then
                read -p "Enter updated priority (high/medium/low): " new_priority
                id="$(echo "$task" | cut -d':' -f1)"
                task_original="$(echo "$task" | cut -d':' -f2)"
                tasks[i]="$id:$task_original:$new_priority"   # Update array
            
            elif [[ $choice == 3 ]]; then
                read -p "Enter updated task: " new_task
                read -p "Enter updated priority (high/medium/low): " new_priority
                id="$(echo "$task" | cut -d':' -f1)"
                tasks[i]="$id:$new_task:$new_priority"
            else
                echo "Invalid Choice"
            fi
            break  # Stop loop after updating
        fi
    done

    if [[ $found -eq 0 ]]; then
        echo "Task ID $update_task_id not found."
    fi
}




add_task "buy wheat" --low
add_task "Buy groceries" --high
add_task "Do laundry" --medium
add_task "Read a book"
add_task "s1" --medium
add_task "s2" --high
add_task "s3" --high



list_tasks
update_task 3

list_tasks
