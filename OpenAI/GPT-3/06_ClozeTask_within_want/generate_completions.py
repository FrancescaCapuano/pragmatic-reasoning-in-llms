from openai import OpenAI

client = OpenAI(api_key = "")


# read randomised runs of the experiments
experiment_runs_path = "../../../randomised_experiment_runs/06_ClozeTask_within_want/"

# 20 runs
for i in range(1,21):

  # open each experiment run and clean to feed to GPT
  run = open(experiment_runs_path + "run" + str(i) + ".txt", "r").readlines()
  run = [item.strip() for item in run] # each item ended with a newline
  run = [item[:-4] for item in run] # get rid of "%%." 

  responses = []


  # open file to store GPT answers
  with open("completions/run" + str(i) + "_answers.txt", "w") as run_answers:

    for item in run:

      # make a call for each item
      gpt_answer = client.completions.create(
        model="davinci-002",
        prompt=item,
        temperature=1,
        max_tokens=20,
        top_p=1,
        frequency_penalty=0,
        presence_penalty=0,
        stop=["."] # stop as soon as a fullstop is encountered
      ) 

      run_answers.write(item + gpt_answer.choices[0].text + ".\n")