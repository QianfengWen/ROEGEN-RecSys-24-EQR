#!/bin/bash

# Prompt user for inputs
echo "This script requires 7 or 8 inputs in the following order:"
echo "1. Original Query Input Path"
echo "2. Processed Query Output Directory"
echo "3. Embedding Type"
echo "4. Document Chunks Directory"
echo "5. Document Embeddings Directory"
echo "6. Retriever type"
echo "7. Retriever Output Directory"
echo "8. Ground Truth Path"
echo "Please ensure you have provided all inputs in the correct order."

# Check if exactly 5 or 6 arguments are provided
if [ "$#" -ne 7 ] && [ "$#" -ne 8 ]; then
    echo "Illegal number of parameters. Please provide 6 or 7 parameters."
    exit 1
fi

# Define the path to the project root directory
project_root=$(dirname $(dirname $(realpath $0)))

# Assign arguments to variables
original_query_input_path=$1
processed_query_output_dir=$2
emb_type=$3
doc_chunks_dir=$4
doc_embeddings_dir=$5
retriever_type=$6
retriever_output_dir=$7
ground_truth_path=$8


# modes=("none" "gqr" "q2e" "q2d" "geqe", "genqr")
modes=("geqe")

for query_processor_mode in "${modes[@]}"; do
    # Extend processed_query_output_dir to include mode-specific subdirectory and filename
    processed_query_output_path="${processed_query_output_dir}/processed_query_${query_processor_mode}.pkl"
    retriever_output_path="${retriever_output_dir}/dense_results_${emb_type}_${query_processor_mode}.json"


    # Define an array of commands or script paths for each mode
    tasks=(
        "echo 'Run Query Processor'"
        "python -m src.QueryProcessor.queryProcessorRunner -i $original_query_input_path -o $processed_query_output_dir --mode $query_processor_mode"
        "echo 'Run dense retriever'"
        "python -m src.Retriever.retrieverRunner -q $processed_query_output_path -c $doc_chunks_dir -e $doc_embeddings_dir -x "dense" --emb_type $emb_type -o $retriever_output_path"
        "echo 'Saving ranked list'"
        "python -m src.Retriever.saveRankList -r $retriever_output_path -o $retriever_output_dir"
    )

    # Loop through the tasks and execute them for the current mode
    for task in "${tasks[@]}"; do
        echo "Executing: $task"
        eval $task
        if [ $? -ne 0 ]; then
            # Handle error
            echo "Task failed: $task"
            exit 1
        fi
    done

    ranked_list_path="${retriever_output_dir}/rank_list_${query_processor_mode}.json"

    # If gound truth is provided, evaluate the retriever output
    if [ -n "$ground_truth_path" ]; then
        echo "Evaluating the retriever output"
        evaluator=("precision" "rprecision" "recall" "map")
        for eval in "${evaluator[@]}"; do
            # if eval is rprecision, then k is not required
            if [ "$eval" == "rprecision" ]; then
                echo "Evaluating: $eval"
                python -m src.Evaluator.evaluatorRunner -e $eval -j $ranked_list_path -g $ground_truth_path -o ${retriever_output_dir}/evaluator_results/${query_processor_mode}_${eval}.json
            else
                for k in 10 30 50; do
                    echo "Evaluating: $eval @ $k"
                    python -m src.Evaluator.evaluatorRunner -e $eval -k $k -j $ranked_list_path -g $ground_truth_path -o ${retriever_output_dir}/evaluator_results/${query_processor_mode}_${eval}_at${k}.json
                done
            fi

        done

        echo "Making tables"
        python -m src.Evaluator.viewResults ${retriever_output_dir}/evaluator_results

    fi
done



echo "All tasks completed successfully."