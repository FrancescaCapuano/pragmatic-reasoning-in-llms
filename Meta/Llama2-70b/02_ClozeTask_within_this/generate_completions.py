import replicate
import os
import random

random.seed(123)

os.environ["REPLICATE_API_TOKEN"] = ""


# read randomised runs of the experiments
experiment_runs_path = "../../../../randomised_experiment_runs/02_ClozeTask_within_this/"

# 20 runs
for i in range(1,21):

  # open each experiment run and clean to feed to Llama
  run = open(experiment_runs_path + "run" + str(i) + ".txt", "r").readlines()
  run = [item.strip() for item in run] # each item ended with a newline
  run = [item[:-4] for item in run] # get rid of "%%." used in the ChatGPT experiment

  responses = []

  # open file to store Llama answers
  with open("completions/run" + str(i) + "_answers.txt", "w") as run_answers:

    for item in run:
      run_answers.write("Item: " + item + " ")

      input = {
          "prompt": item, #"This is not a dog, it is",
          "temperature": 0.75,
          "max_new_tokens": 20,
          "top_p": 1,
          "seed": random.randrange(1,1000),
          "stop_sequences": '.',
      }

      for output in replicate.run("meta/llama-2-70b", input=input):
          run_answers.write(str(output))
      run_answers.write(".\n")

