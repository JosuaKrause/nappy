# Playtest downy-beaver — Other people's feedback is summarised, never quoted, and never a request

2026-10-24.

## #820

1. **Context** (the assistant's):

   Said on 2026-10-24 after the orchestrator offered to capture a Reddit commenter's suggestion into the inbox and quoted that commenter word for word in the conversation, while reading the replies to the player's r/ClaudeGameDev post with tools/reddit.py.

2. **The note.**

   > let's not put other people's comments into the inbox.
   >
   > never directly quote other people's comments, though. they didn't consent to being recorded. you can give rough summaries what people say.

3. **Read as:** (the assistant's interpretation, not the player's words)

   What people outside the project write (Reddit comments, replies, any public post) is never captured into the inbox, and is never quoted word for word in anything the project records (stats files, notes, queue entries, records, PRs, issues) or in the conversation; it may be given as a rough summary in the agent's own words. The rule belongs in the skills that read Reddit and capture notes (using-tools' tools/reddit.py row, inbox).

4. **Context** (the assistant's):

   The player's answer when asked whether a rule for feedback from people other than the player should be filed with this note, as a docs PR, in these four points (point 4 the orchestrator's addition, marked as such when asked; points 1 and 3 the orchestrator's wording; point 2 is this note's own words):
   1. Other people's feedback is evidence, never a request. Reddit replies, other playtesters and outside issues never go into the inbox, the queue or the review items by themselves; they become work only through the player's words: the agent brings the player a summary, and what the player decides is what gets captured.
   2. It is summarised, never quoted: no words, usernames or post titles go into the repository, issues, pull requests or the conversation, since they did not agree to being recorded.
   3. Where it is kept: a rough summary may sit next to the data it explains (as in a stats file), labelled as other people's view and never mixed with the player's words.
   4. How it is weighed: one person's report is a single data point; it carries weight when the numbers back it up (as the day-1 confusion lines up with 1 win in 12 day-1 attempts).
   The rule goes in playtest-feedback, with a pointer from the tools/reddit.py row of the using-tools catalogue.

5. **The player's words.**

   > sounds good
