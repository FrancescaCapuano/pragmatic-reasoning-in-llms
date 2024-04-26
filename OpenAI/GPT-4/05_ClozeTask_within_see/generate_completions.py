from os import listdir
from os.path import isfile, join
from openai import OpenAI

client = OpenAI(api_key = "")


# read randomised runs of the experiments
experiment_runs_path = "../../randomised_experiment_runs/05_ClozeTask_within_see/"

# start with 10
for i in range(1,21):

  # open each experiment run and clean to feed to GPT
  run = open(experiment_runs_path + "run" + str(i) + ".txt", "r").readlines()
  run = [item.strip() for item in run] # each item ended with a newline
  run = [item[:-4] for item in run] # get rid of "%%." used in the ChatGPT experiment

  responses = []


  # open file to store GPT answers
  with open("completions/run" + str(i) + "_answers.txt", "w") as run_answers:

    for item in run:

      gpt_answer = client.chat.completions.create(
        model="gpt-4",
        messages=[
          {
            "role": "user",
            "content": item
          }
        ],
        temperature=1,
        max_tokens=20,
        top_p=1,
        frequency_penalty=0,
        presence_penalty=0,
        stop=["."]
      )

      run_answers.write(item + " " + gpt_answer.choices[0].message.content + ".\n")