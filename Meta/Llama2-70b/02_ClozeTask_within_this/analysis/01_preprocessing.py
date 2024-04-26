from os import listdir
from os.path import isfile, join
import nltk
from nltk.corpus import stopwords 
import re
import pandas as pd
import string
from nltk.corpus import wordnet

# all experimental runs
runs = [f for f in listdir("../completions/") if f.endswith(".txt")]

# initialise dataframe
df = pd.DataFrame.from_dict({"Subject" : [] * 50, "Polarity" : [], "Item" : [], "Answer" : []})

# for each run
for r in runs:

	# get a run ID
	subject = re.search('run(.*)_answers', r).group(1)

	# initialise polarity, item and answer
	polarity = list()
	item = list()
	answer = list()

	with open("../completions/" + r) as r:
		r = [answer.strip() for answer in r.read().split("Item: ") if answer] 
		r = [answer.split(".")[0] + "." for answer in r]

		for line in r:

			split_line = line.split()

			# sentence polarity
			if split_line[2] == "not":
				polarity.append("negative")
				# answer
				answer.append(re.findall(", it (.*).", line)[0].split())
			else:
				polarity.append("affirmative")
				# answer
				answer.append(re.findall(", and that (.*).", line)[0].split())

			# item
			stop_words = set(stopwords.words('english')) 
			item.append([w for w in split_line if not w in stop_words][1].strip(","))




	d = {"Subject" : [subject] * 50, "Polarity" : polarity, "Item" : item, "Answer" : answer}

	df_subject = pd.DataFrame.from_dict(d)

	df = df._append(df_subject)


# CLEAN ANSWERS (same as in the real people study)
df['Answer'] = df['Answer'].astype(str)
# strip
df['Answer'] = df['Answer'].str.lower().str.strip()

# remove nan answers (catches what used to be numeric answers)
df = df.dropna(subset=['Answer'])

# remove punctuation (except "-")
my_punctuation = string.punctuation.replace("-","")
df['Answer'] = df['Answer'].str.translate(str.maketrans('', '', my_punctuation))

# remove stopwords
stop_words = set(stopwords.words('english')) 
df['Answer'] = [[w for w in str(a).split() if not w in stop_words or w == "can"] for a in df['Answer']] 

# keep only answers consisting of one word
is_only_one_word = df['Answer'].str.len() == 1
df = df[is_only_one_word]

# remove any empty answer left (doesn't seem to be doing anything but double check)
df['Answer'] = [' '.join(a) for a in df['Answer']]
is_not_empty = df['Answer'] != ""
df = df[is_not_empty]

# keep only nouns
noun = []
for w in df['Answer']:
	w_pos = set([ss.pos() for ss in wordnet.synsets(w)])
	noun.append("n" in w_pos)
df['Could.Be.Noun'] = noun
could_be_noun = df['Could.Be.Noun'] == True
df = df[could_be_noun]

# remove items == answer
df = df[df['Answer'] != df['Item']]

# drop useless cols
df = df.drop(['Could.Be.Noun'], axis = 1)

# save
df.to_csv("cleaned_completions.csv", index = False)