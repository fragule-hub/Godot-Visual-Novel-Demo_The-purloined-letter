# Chapter 3: The Two of Them and the Clubroom


# Scene 3-1: Where would a letter be hidden?
background test_room fade

"Me" "You've been standing there ever since Eve finished. Something on your mind?"

# Clara didn't turn around

actor show Clara face=neutral at 1
"Clara" "Thinking about a problem, but so far I've only got a wall. {change:Clara,preset:body_coat|face=happy}"

"Me" "What problem?"

"Clara" "If I were hiding a letter, where would I hide it? Every spot I can think of, Eve has already searched."

"Me" "You? You'd hide it in a drainpipe."

# Clara looked back at me

"Clara" "A drainpipe?"

"Me" "You've climbed the drainpipe on the north building's third floor. Hiding something there would be the most natural thing in the world for you."

"Clara" "...What kind of misunderstanding do you have about me? I'm not a sewer ninja."

"Me" "You're the Monkey of the Evening Moon. What's the difference?"

# Clara huffed, but didn't argue

"Me" "But this question isn't about you. It's about the person who took the letter -- she's careful, and she's confident."

"Me" "Eve searched for two weeks. Checked every hidden corner. What's the conclusion?"

"Clara" "The letter isn't in any hidden corner."

"Me" "Then there's only one possibility --"

# Choice 3: Where is the letter?

choice "Hidden in a drainpipe or outside the window" -> c3_pipe
choice "Hidden deep inside a book or furniture compartment" -> c3_hidden
choice "Hidden somewhere Eve checked but didn't think of as a hiding spot" -> c3_plain

branch c3_pipe:
    "Me" "Outside the window. Drainpipe, gaps in the outer wall, behind the AC unit."
    "Clara" "Nice. {change:Clara,preset:dir_left|face=happy}"
    "Me" "Correct?"
    "Clara" "Very much my style."
    "Me" "So?"
    "Clara" "So it's wrong. The other person isn't me."
    actor show Eve neutral at 2
    "Eve" "Besides, that outer wall has been drawing too much attention lately."
    "Me" "Because of the shadow sightings."
    "Clara" "Don't look at me."
    "Me" "I haven't even said anything."
    jump_branch c3_retry

branch c3_hidden:
    "Me" "Books, furniture, mattresses, hidden compartments in wardrobes. Want to do another thorough search?"
    actor show Eve neutral at 2
    "Eve" "Theoretically, that's not possible. {change:Eve,neutral}"
    "Clara" "I trust Eve's search skills. Just like I trust my own detective abilities."
    "Me" "Detective abilities?"
    "Clara" "When you pick a lock, you can tell if there's something foreign inside the cylinder the moment you turn it. Eve searching a room is the same principle."
    "Me" "Uh... should I be roasting you for that?"
    "Clara" "Pretty professional, right?"
    "Me" "Pretty dangerous."
    jump_branch c3_retry

branch c3_retry:
    "Me" "Let's change the question. If someone knew Eve would search the room, and knew Eve is very good at searching, what would she do?"
    "Clara" "Stay out of Eve's area of expertise. {change:Clara,preset:body_coat|face=happy}"
    "Me" "Right. She wouldn't hide the letter in a hidden spot."
    "Clara" "Which means..."
    "Me" "She might put it somewhere Eve wouldn't think of as a hiding spot."
    jump_branch c3_plain

branch c3_plain:
    "Me" "The letter might be hidden in plain sight."
    actor show Eve neutral at 2
    "Eve" "Plain sight? {change:Eve,surprise}"
    "Me" "The other person knows you'll check secret compartments, hidden layers, mechanisms, and containers. So she probably wouldn't bet everything on those places."
    "Clara" "Because doing that would actually get her caught by Eve."
    "Eve" "But it's not like I didn't check the things in plain sight. {change:Eve,neutral}"
    "Me" "You checked whether they were hiding something. But if the letter isn't in a hidden spot, it might just be mixed in among the plain-sight items you already looked at."
    "Eve" "...{wait_pause:2,3}"
    "Clara" "Plain-sight items?! {bounce:Clara,1,10,0.18}"
    "Me" "Right. Desk, letter rack, bulletin board, document box -- anywhere you can see without opening a secret compartment."
    "Eve" "But there are a lot of things in plain sight. Specifically, what kind?"
    "Me" "I don't know."
    "Me" "I can't know yet. I can only deduce that it's not necessarily hidden, and is probably in plain sight. But what form it takes there -- that needs on-site confirmation. {wait:0.8}"
    "Clara" "So we're not looking for secret compartments. We're looking at things that have already been seen, but weren't treated as targets. {change:Clara,preset:body_coat|face=happy}"
    "Me" "Especially things you'd never suspect again after checking them once."
    jump_branch c3_continue

branch c3_continue:

    # Scene 3-2: Narrowing the Theory
    scene_break test_room fade

    "" "Eve slowly lowered her head."

    actor show Eve neutral at 2

    "Eve" "Things you'd never suspect again after they've been checked... {change:Eve,neutral}"

    "" "She mentally traced back through her search checklist."

    "Eve" "Things on the top layer. The kind you can see at a glance and tell just by touching that they have no hidden compartments. The pen holder on the desk, the lamp base, the picture frame -- I've felt all of them. No compartments, no signs of modification."

    actor show Clara face=neutral at 1

    "Clara" "So you wouldn't take them apart to check again. {change:Clara,preset:body_coat|face=happy}"

    "Eve" "No."

    "Me" "That's exactly it. That's the effect the other person was going for. {wait:0.5}"

    "" "Clara paced a few steps around the room."

    "Clara" "But 'plain sight' is too broad. There are at least dozens of things out in the open in that room. Pen holder, lamp, books, letter rack, bulletin board, decorations --"

    "Me" "So we need to narrow it down further."

    "Eve" "How?"

    "Me" "If the letter is in plain sight and you checked it but didn't recognize it -- then it definitely isn't there in the form of a 'letter.' Or at least, not in its original form. {wait:0.8}"

    # Clara stopped pacing

    "Clara" "A disguise? {bounce:Clara,1,10,0.18}"

    "Me" "Right. The other person turned the letter into something else."

    "Eve" "Into what? {change:Eve,neutral}"

    "Me" "I don't know. But we can narrow the possibilities."

    "" "I picked up a sticky note from the table and folded it idly."

    "Me" "A letter is essentially a piece of paper. If it's no longer in letter form -- what could it be?"

    "Clara" "A book page. Slipped inside a book."

    "Eve" "The book's thickness would change. I've checked every book on the shelf. If something was tucked inside, I'd know just by feeling it."

    "Clara" "What about a notebook? A homework pad? Scrap paper?"

    "Eve" "Same thing. If the thickness is off, it'll be found."

    "Me" "So the disguise can't be 'slipping something in.' The paper itself must have become something else."

    "Clara" "If paper became another piece of paper -- like, a letter turned into a different letter? {wait:0.5}"

    "Clara" "Eve, is there a place for letters in that room?"

    "Eve" "There's a wall-mounted letter rack next to the desk. The kind that hangs on the wall. A few letters inside."

    "Clara" "Did you search it?"

    "Eve" "I did. Picked up every single one. Thickness, envelope, addressee -- all normal. And those letters were all old. The creases and wear were genuine."

    # Clara looked at me
    actor change Clara preset:dir_left|face=happy
    "Clara" "Vice President."

    "Me" "If the other person carefully folded the letter back along its original creases and wrote a new address on the outside --"

    "Clara" "-- then it would look like a completely different letter. {change:Clara,preset:dir_left|face=happy}"

    "Me" "The addressee doesn't match, and even if the size is similar, it looks nothing like the original. So you skipped it during your search."

    "Clara" "Thickness stays the same. Nothing tucked inside. No multiple seals."

    "Me" "That way, by Eve's definition, it's already 'impossible to be the target.'"

    # Eve slowly pressed her hand to her forehead

    "Eve" "This is just speculation. {change:Eve,angry}"

    "Clara" "But it's reasonable speculation."

    "Eve" "If that's really the case -- the letter might have a new sealing sticker, a new addressee name. It would look like just some random ordinary letter casually left in the letter rack. {change:Eve,cry}"

    "Eve" "I saw it. I might have even picked it up. But when I saw the addressee wasn't right, the appearance didn't match -- I put it back. {change:Eve,neutral}"

    "Me" "Because you were looking for 'a hidden letter.' Not 'a letter disguised as a different letter.'"

    # Scene 3-3: Clara Takes Action
    scene_break test_room fade

    "" "Clara suddenly stood up."

    play bgm battle
    actor show Clara face=neutral at 1
    "Clara" "Hehe~ Reasoning really gets the blood pumping! {change:Clara,preset:dir_left|face=happy}{bounce:Clara,2,30,0.18}"

    "Clara" "Now that the reasoning's gotten this far, someone's going to have to go confirm it with their own eyes!"

    "" "I looked at her helplessly."
    actor show Eve neutral at 2
    "" "Eve looked at her."

    "Clara" "If you go into her room again, she'll get suspicious. But if it's me --"

    "Me" "You... certainly wouldn't be stopped by a door."

    "Clara" "I prefer windows over doors, you know. {change:Clara,preset:dir_left|face=happy}"

    "Me" "..."

    "" "Clara headed for the window as she spoke -- she never wasted time once she'd made a decision."

    actor change Clara preset:dir_left|preset:body_coat|face=happy

    "Me" "But wait..."

    "" "I slowly looked toward the window."

    "Me" "You're not planning to go right now, are you?"

    "Clara" "Yep."

    "Me" "At least explain how you plan to get in first."

    "Clara" "You already know, don't you?"

    "" "Eve looked like she wanted to say something, but swallowed it back down."
    "" "She had already turned that place upside down, but as the Student Disciplinary Committee Chair, being complicit in a break-in was... a bit awkward."
    "" "I sighed helplessly."
    "" "Clara looked at me."

    "Clara" "Vice President, what do you say?"

    "Me" "I say, at least don't get caught."

    "Clara" "Mission accepted. {change:Clara,preset:dir_left|face=happy}"

    "Eve" "You two... {change:Eve,neutral}"

    "Me" "If we go through official channels, the other person might have time to deal with the letter."

    "Me" "But right now, she's confident that Eve has been completely fooled, so she won't make any changes to the letter."

    "Eve" "..."

    "Clara" "Relax, I'll just confirm, not rummage around."

    "Me" "That sentence coming from you has very low credibility."

    "Clara" "Then make me some tea."

    "Me" "Don't change the subject... whatever."

    "" "I watched her for a moment, then got up to get the teapot and cups. I was just about to bring them over."

    "Clara" "Keep the tea warm. I'll be right back. {change:Clara,preset:dir_left|preset:body_coat|face=happy}{bounce:Clara,1,10,0.18}"

    "" "I laughed."

    "Me" "Should I play the Guan Yu theme song now?"

    "Clara" "Let's not."

    "" "{bounce:Clara,1,10,0.18}She opened the window and vaulted onto the sill with one hand."

    "Eve" "Third floor."

    "Clara" "I know."

    "Me" "That's the scariest part."

    actor exit Clara

    "" "After a brief gust of wind, only the sound of cicadas remained outside the window."
    "" "..."
    "" "Suddenly, a voice came from outside the window."

    "Clara" "Hey, do you know which room she's in?"

    "Eve" "...404."

    "Clara" "Got it!"

    "Eve" "...This probably doesn't count as incitement to commit a crime, right?"

    "Me" "If you don't get caught, it's not a crime."

    # Scene 3-4: The Payment Question
    scene_break test_room fade

    play bgm circulation

    "" "Eve stared in the direction of the window, her expression that of someone trying very hard not to think about the physical reality of a person scaling the outer wall of a three-story building."

    "Me" "She's more familiar with the routes than most of the building's drainpipes."

    # Eve turned her head

    actor show Eve neutral at 2
    "Eve" "Is that supposed to be reassuring? {change:Eve,neutral}"

    "Me" "It's a factual statement."

    # Eve was silent for a second

    "Eve" "...You seem pretty used to this."

    "Me" "Spend a semester sharing a room with her, and you'll get used to it too. Either get used to it, or transfer early."

    "" "Eve's lips twitched, her expression full of resignation."

    "" "..."
    "" "..."
    "" "Silence..."
    "" "Having spent so much time with someone as roast-worthy as Clara, how do you even start a conversation with someone who's completely flawless?"
    "" "I seem to have completely forgotten how... wait, I never knew how in the first place, did I?"
    "" "..."

    "" "I placed the teacup on the table."

    "Me" "Come to think of it, a commission should have payment, right? {change:Eve,surprise}"

    # Eve was slightly startled

    "Eve" "{change:Eve,neutral}In theory, it should be requested from the letter's owner."

    "Eve" "But technically, I was the one who commissioned this. If you want payment, just ask me."

    "" "She said it so earnestly."
    "" "I was going to give a casual reply, but for some reason, a mischievous urge to tease her welled up inside me."

    # Choice 4: Asking for Payment

    choice "No payment needed" -> c4_none
    choice "Go out with me" -> c4_date_pre
    choice "One million" -> c4_million

branch c4_none:
    "Me" "No payment needed."
    "Eve" "Why? {change:Eve,neutral}"
    "Me" "If it were Clara, she'd say the same thing."
    "Eve" "When you put it that way, I understand. {change:Eve,smile}"
    "Me" "She'd say it's a detective's duty. Then pocket the cookies on your desk."
    "Eve" "Then come have cookies at my place next time."
    "Me" "Just make sure you don't reward her by letting her climb in through the window."
    "Eve" "I'll make sure to lock the window. {change:Eve,smile}"
    "Me" "Then she might pick the lock."
    "Eve" "I'll get a harder lock to pick. {change:Eve,neutral}"
    "" "I smiled quietly to myself. A lock that could keep out Clara -- does such a thing really exist? That would be yet another great unsolved mystery..."
    jump_branch c4_merge

branch c4_date_pre:
    play bgm pink_blood
    "Me" "Then go out with me."
    "Eve" "G-go-go out? {change:Eve,surprise}"
    "Me" "Yeah."
    "Eve" "You mean going out as in, socializing?"
    "Me" "We're already doing that."
    "Eve" "W-wait wait wait wait. {change:Eve,shy}Normally when someone's in this kind of situation, wouldn't they ask for something more... adult? What do you mean by going out... is this some kind of flirting? {speed:55}"
    "Me" "... "
    "Eve" "...{wait:1.5}"
    "" "{change:Eve,surprise}Eve's expression shifted from shock to blankness, then from blankness to bright red. {change:Eve,shy}"
    "Eve" "I didn't say anything just now."
    jump_branch date_sub_choice

branch date_sub_choice:
    choice "You said a lot just now" -> date_tease
    choice "Did you say something just now" -> date_let_off

branch date_tease:
    "Me" "{change:Eve,neutral}You said a lot just now."
    "Eve" "No. The Disciplinary Committee Chair has never used such words. {change:Eve,shy}"
    "Me" "I haven't even pointed out which words yet."
    "Eve" "Please don't."
    "Me" "Fine."
    jump_branch date_merge

branch date_let_off:
    "Me" "Did you say something just now?"
    "Eve" "{change:Eve,neutral}Y-yeah, did I say something just now?"
    "Me" "Nope, nothing at all."
    "Eve" "...Thank you."
    jump_branch date_merge

branch date_merge:
    "" "{change:Eve,neutral}Eve lowered her head and stared at her teacup, as if trying to hide herself inside it."
    "Eve" "So... um, is this some kind of joke? {change:Eve,shy}"
    "Me" "Why would you think that? There must be plenty of people who'd want to ask you out."
    "Eve" "There aren't. Someone like me, who's boring and not even good-looking..."
    "Me" "That's not true."
    "Eve" "Am I interesting?"
    "Me" "I wouldn't deny it."
    "Eve" "What does that mean... ah, ah... {change:Eve,shy}"
    "" "She looked like she desperately wanted to change the subject."
    "Eve" "Come to think of it, that kind of payment wouldn't be fair. Clara hasn't said anything about it."
    "Me" "She'd definitely say she doesn't want anything. So it's fine for me to take care of everything."
    "Eve" "...I didn't hear anything. Is that okay? {change:Eve,shy}"
    "Me" "That works, I guess. But don't you want to hear the rest?"
    "Eve" "...After this is all over. {change:Eve,smile}{wait:2.0}"
    "" "She spoke very softly. So softly that if I had accidentally coughed, her words would have been blown away."
    "Me" "Okay. {wait:1.0}"
    play bgm circulation
    jump_branch c4_merge

branch c4_million:
    "Me" "One million."
    "Eve" "Cash or transfer? {change:Eve,neutral}"
    "Me" "Why are you already going through the process?"
    "Eve" "But I don't have that much cash on me."
    "Me" "It's not about the cash."
    "Eve" "And this whole thing needs to be kept quiet, so I can't ask others for money. My parents are strict too, and the available balance in my account is limited."
    "Me" "Stop."
    "Eve" "I can give you all my allowance. The rest in installments."
    "Me" "Stop. Really, stop."
    "Eve" "Not enough?"
    "Me" "I was joking."
    "Eve" "Joking? {change:Eve,surprise}"
    "Me" "I just wanted to see your reaction to a huge amount."
    "Eve" "Huge amount? {change:Eve,surprise}"
    "Me" "...No, never mind, forget I said it. It was just a joke."
    "" "Eve didn't laugh. She lowered her head and pulled a stack of bills from her wallet."
    "Eve" "{change:Eve,neutral}Jokes aside. A commission must have payment. That's a principle."
    "Me" "...You're serious?"
    "Eve" "This is all the cash I have for now. I'll make up the rest later."
    "Me" "Do you know how much the Detective Club's annual budget is?"
    "Eve" "No."
    "Me" "About this much."
    "Eve" "Then that's perfect. {change:Eve,smile}"
    "" "Looking at her earnest expression, I realized that refusing any further would be an insult to her principles."
    "" "I accepted the money."
    "Me" "Fine."
    "Eve" "I'll continue to give you the rest later."
    "Me" "...No, really, you don't need to give that much. {speed:40}"
    "" "As for this money, I'll just put it toward club expenses later."
    jump_branch c4_merge

branch c4_merge:
    "" "A faint sound came from outside the window."
    "" "Eve and I both looked toward the window at the same time."
    "" "A hand gripped the windowsill."

    "Me" "The tea's still warm."
    # Clara's voice from outside the window
    play bgm battle
    "Clara" "Then that means I'm back right on time."

    jump_id chapter4 erase
