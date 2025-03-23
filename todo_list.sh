#!/bin/bash

TODO_FILE="todo.txt"
DONE_FILE="done.txt"

touch "$TODO_FILE"
touch "$DONE_FILE"


add_task() {
    local task="$1"
    local priority="medium"

    case "$2" in
        --high) priority="high" ;;
        --medium) priority="medium" ;;
        --low) priority="low" ;;
    esac

    # Generate a unique ID (hash of task + timestamp)
    local task_id
    task_id=$(echo -n "$task$(date +%s%N)" | md5sum | cut -c1-8)

    echo "$task_id:$task:$priority" >> "$TODO_FILE"
    echo "Task added: '$task' (Priority: $priority) [ID: $task_id]"
}





list_tasks() {
    if [[ ! -s "$TODO_FILE" ]]; then
        echo "No tasks available."
        return
    fi
    printf "Tasks Remaining\n\n"
    awk -F':' '{printf "%s: %s (Priority: %s)\n", $1, $2, $3}' "$TODO_FILE"

    printf "\nTasks Done\n\n"
    awk -F':' '{printf "%s: %s (Priority: %s)\n", $1, $2, $3}' "$DONE_FILE"
}

remove_task() {
    local task_id="$1"
    if [[ ! -s "$TODO_FILE" ]]; then
        echo "No tasks to remove."
        return
    fi

    if grep -q "^$task_id:" "$TODO_FILE"; then
        sed -i "/^$task_id:/d" "$TODO_FILE"
        echo "Task $task_id removed."
    else
        echo "Invalid task ID!"
    fi
} 

# sort_tasks() {
#     local n=${#tasks[@]}

#     for ((i = 0; i < n - 1; i++)); do
#         for ((j = 0; j < n - i - 1; j++)); do

#             local task1="${tasks[j]}"
#             local task2="${tasks[j+1]}"
#             local p1="${task1##*:}"
#             local p2="${task2##*:}"

#             if [[ $(priority_rank "$p1") -lt $(priority_rank "$p2") ]]; then
#                 temp="${tasks[j]}"
#                 tasks[j]="${tasks[j+1]}"
#                 tasks[j+1]="$temp"
#             fi
#         done
#     done

#     echo "Tasks Sorted"

# }


sort_tasks() {
    if [[ ! -s "$TODO_FILE" ]]; then
        echo "No tasks available to sort."
        return
    fi

    mapfile -t tasks < "$TODO_FILE"

    
    local n=${#tasks[@]}
    for ((i = 0; i < n - 1; i++)); do
        for ((j = 0; j < n - i - 1; j++)); do
            task1="${tasks[j]}"
            task2="${tasks[j+1]}"

            p1=$(priority_rank "$(echo "$task1" | awk -F':' '{print $3}')")
            p2=$(priority_rank "$(echo "$task2" | awk -F':' '{print $3}')")

            if [[ $p1 -lt $p2 ]]; then
                temp="${tasks[j]}"
                tasks[j]="${tasks[j+1]}"
                tasks[j+1]="$temp"
            fi
        done
    done

    printf "%s\n" "${tasks[@]}" > "$TODO_FILE"
    echo "Tasks sorted by priority (high > medium > low)."
}


clear_tasks() {
    if [[ ! -s "$TODO_FILE" ]]; then
        echo "No tasks to clear."
        return
    fi

    > "$TODO_FILE"
    > "$DONE_FILE"
    echo "All tasks cleared."
}

priority_rank() {
    case "$1" in 
        high) echo 3 ;;
        medium) echo 2 ;;
        low) echo 1 ;;
        *) echo 0 ;;
    esac
}

# update_task() {
#     local update_task_id="$1"
#     local found=0

#     for i in "${!tasks[@]}"; do
#         task="${tasks[i]}"
#         task_id="${task%%:*}"

#         if [[ "$task_id" == "$update_task_id" ]]; then  
#             found=1

#             echo "Choose what you want to update"
#             echo "1: Task"
#             echo "2: Priority"
#             echo "3: Both"

#             read -p "Enter your choice: " choice

#             if [[ $choice == 1 ]]; then
#                 read -p "Enter updated task: " new_task
#                 id="$(echo "$task" | cut -d':' -f1)"
#                 priority="$(echo "$task" | cut -d':' -f3)"
#                 tasks[i]="$id:$new_task:$priority"
            
#             elif [[ $choice == 2 ]]; then
#                 read -p "Enter updated priority (high/medium/low): " new_priority
#                 id="$(echo "$task" | cut -d':' -f1)"
#                 task_original="$(echo "$task" | cut -d':' -f2)"
#                 tasks[i]="$id:$task_original:$new_priority"
            
#             elif [[ $choice == 3 ]]; then
#                 read -p "Enter updated task: " new_task
#                 read -p "Enter updated priority (high/medium/low): " new_priority
#                 id="$(echo "$task" | cut -d':' -f1)"
#                 tasks[i]="$id:$new_task:$new_priority"
#             else
#                 echo "Invalid Choice"
#             fi
#             break
#         fi
#     done

#     if [[ $found -eq 0 ]]; then
#         echo "Task ID $update_task_id not found."
#     fi
# }

update_task() {
    local update_task_id="$1"
    if [[ ! -s "$TODO_FILE" ]]; then
        echo "No tasks to update."
        return
    fi

    if grep -q "^$update_task_id:" "$TODO_FILE"; then
        echo "Choose what you want to update"
        echo "1: Task"
        echo "2: Priority"
        echo "3: Both"

        read -p "Enter your choice: " choice
        if [[ $choice == 1 ]]; then
            read -p "Enter updated task: " new_task
            local priority=$(grep "^$update_task_id:" "$TODO_FILE" | cut -d: -f3)
            sed -i "s/^$update_task_id:.*:$priority\$/$update_task_id:$new_task:$priority/" "$TODO_FILE"
        
        elif [[ $choice == 2 ]]; then
            read -p "Enter updated priority (high/medium/low): " new_priority
            local task_name=$(grep "^$update_task_id:" "$TODO_FILE" | cut -d: -f2)
            sed -i "s/^$update_task_id:$task_name:.*/$update_task_id:$task_name:$new_priority/" "$TODO_FILE"

        elif [[ $choice == 3 ]]; then
            read -p "Enter updated task: " new_task
            read -p "Enter updated priority (high/medium/low): " new_priority
            sed -i "s/^$update_task_id:.*:.*/$update_task_id:$new_task:$new_priority/" "$TODO_FILE"
        
        else
            echo "Invalid Choice"
        fi
    else
        echo "ID not found"
    fi
}

deduplicate_tasks() {
    if [[ ! -s "$TODO_FILE" ]]; then
        echo "No tasks available to deduplicate."
        return
    fi

    awk -F':' '!seen[$2]++' "$TODO_FILE" > temp.txt && mv temp.txt "$TODO_FILE"

    echo "Duplicate tasks removed, keeping the first occurrence."
}


task_done() {
    local task_id="$1"

    if [[ ! -s "$TODO_FILE" ]]; then
        echo "No tasks present."
        return
    fi

    if grep -q "^$task_id:" "$TODO_FILE"; then
        local task_entry=$(grep "^$task_id:" "$TODO_FILE")
        echo "$task_entry" >> "$DONE_FILE"

        # Remove from TODO_FILE
        sed -i "/^$task_id:/d" "$TODO_FILE"

        echo "Task $task_id marked as done"
    else
        echo "Invalid task ID!"
    fi
}






# add_task "buy wheat" --low
# add_task "Buy groceries" --high
# add_task "Do laundry" --medium
# add_task "Read a book"
# add_task "s1" --medium
# add_task "s2" --high
# add_task "s3" --high



# list_tasks
# update_task 3

# list_tasks

help_menu() {
    echo "Usage: ./todo_list.sh [OPTION] [ARGUMENTS]"
    echo
    echo "Options:"
    echo "  -a \"task\" --PRIORITY   Add a task with the specified priority (low, med, high)"
    echo "  -l                     List all tasks"
    echo "  -r ID                  Remove a task by its ID"
    echo "  -s                     Sort tasks by priority"
    echo "  -c                     Clear all tasks"
    echo "  -u ID                  Update a task's description and priority"
    echo "  -de                    Deduplicate tasks based on description"
    echo "  -dn ID                 Mark a task as done"
    echo
    echo "Examples:"
    echo "  todo.sh -a \"Finish project\" --high   # Add a high-priority task"
    echo "  todo.sh -l                           # List all tasks"
    echo "  todo.sh -r 1234                      # Remove task with ID 1234"
    echo "  todo.sh -s                           # Sort tasks by priority"
    echo "  todo.sh -c                           # Clear all tasks"
    echo "  todo.sh -u 1234                      # Update task 1234"
    echo "  todo.sh -de                          # Remove duplicate tasks"
    echo "  todo.sh -dn 1234                     # Mark task 1234 as done"
    echo
}

# Modify the case statement to include the help option
case "$1" in
    -a) shift; add_task "$1" "$2" ;;
    -l) list_tasks ;;
    -r) shift; remove_task "$1" ;;
    -s) sort_tasks ;;
    -c) clear_tasks ;;
    -u) shift; update_task "$1" "$2" "$3" ;;
    -de) deduplicate_tasks ;;
    -dn) shift; task_done "$1" ;;
    -h|--help) help_menu ;;
    *) echo "Invalid option. Use -h or --help for usage details."; exit 1 ;;
esac

