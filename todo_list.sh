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

    # Here I am generating a unique code for each task
    # 1) Concatenating the task description and current time(in seconds and nanoseconds)
    # 2) passing the output of this md5sum to compute hash for the string
    # 3) next the hash is cut to only include first 8 digits of hash using cut
    local task_id
    task_id=$(echo -n "$task$(date +%s%N)" | md5sum | cut -c1-8)

    # appends the task(id:task_description:priority) to the todo.txt
    echo "$task_id:$task:$priority" >> "$TODO_FILE"
    echo "Task added: '$task' (Priority: $priority) [ID: $task_id]"
}





list_tasks() {

    # for checking if the file exists and has a size greater than 0
    if [[ ! -s "$TODO_FILE" ]]; then
        echo "No tasks available."
        return
    fi
    printf "Tasks Remaining\n\n"

    # used to split the task(id:task_description:priority) on ':' 
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

    # This line checks if the todo.txt has a line starting with given task_id
    # the grep -q is for quite mode that is it doesn't return any output (just for true and false purpose)
    if grep -q "^$task_id:" "$TODO_FILE"; then

        # This finds the line starting with task_id , the / / define a line and the 'd' at the end is to delete that line
        sed -i "/^$task_id:/d" "$TODO_FILE"
        echo "Task $task_id removed."
    else
        echo "Invalid task ID!"
    fi
} 




sort_tasks() {
    if [[ ! -s "$TODO_FILE" ]]; then
        echo "No tasks available to sort."
        return
    fi

    # This stores each line of the todo.txt in tasks array, the  -t is for trimming the new line
    mapfile -t tasks < "$TODO_FILE" 

    # This calculates the number of elements in array
    local n=${#tasks[@]}
    for ((i = 0; i < n - 1; i++)); do
        for ((j = 0; j < n - i - 1; j++)); do
            task1="${tasks[j]}"
            task2="${tasks[j+1]}"

            # split the task on ':' and then passes only the 3rd parameter (priority) to function priority rank
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

    # Used to empty the both todo.txt, done.txt
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

            # using grep to detect a line starting with task_id and cutting on the third parameter(priority)
            local priority=$(grep "^$update_task_id:" "$TODO_FILE" | cut -d: -f3)

            # used for replacing the old task with new task
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

    # awk -f splits the each line of todo.txt
    # seen is an associative array (key:value), if the second parameter(task_description) on a line is seen the value of that line
    # here line is the key and number of times it is seen is value, so if a task_description is seen first time, it is moved
    # to temp.txt and if seen more than 0 times no action
    #after this process we rename the temp.txt as todo.txt
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

        # to remove the line from todo.txt
        sed -i "/^$task_id:/d" "$TODO_FILE"

        echo "Task $task_id marked as done"
    else
        echo "Invalid task ID!"
    fi
}




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
    echo "  ./todo_list.sh -a \"Finish project\" --high   # Add a high-priority task"
    echo "  ./todo_list.sh -l                           # List all tasks"
    echo "  ./todo_list.sh -r 1234                      # Remove task with ID 1234"
    echo "  ./todo_list.sh -s                           # Sort tasks by priority"
    echo "  ./todo_list.sh -c                           # Clear all tasks"
    echo "  ./todo_list.sh -u 1234                      # Update task 1234"
    echo "  ./todo_list.sh -de                          # Remove duplicate tasks"
    echo "  ./todo_list.sh -dn 1234                     # Mark task 1234 as done"
    echo
}

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

