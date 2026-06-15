# Chapter 1: The Sudden Appearance of the Twilight Moon Monkey
# Scene 1-1: The Mystery Club on a Summer Day
background test_room fade

play bgm easygoing

"" "The old school building, third floor, Tsukimori Academy. The Mystery Club's activity room."
"" "Cicada song filters through the glass window, and the hum of the air conditioner is steady enough to feel reassuring. On the desk, detective novels, old newspapers, and a stack of case request forms that nobody has ever bothered to organize are spread out."
"" "This is what the clubroom is like in the summer heat."
"" "Sunlight, cicadas, air conditioning, novels. As long as no one disturbs the peace, this place is practically one of the few havens of comfort at Tsukimori Academy."

"" "A faint metallic scrape came from outside the window."
"" "I turned a page in my book."
"" "The window frame trembled slightly."
"" "I kept reading."
"" "The window was pushed open from outside."
play bgm battle
actor show Clara face=neutral at 1
"" "Clara leaned in halfway through the windowsill, her golden hair tousled by the summer breeze, wearing a smile so bright it absolutely should not have been appearing on the outside of a third-floor window."
"Clara" "Good afternoon, Vice President!{bounce:Clara,1,25,0.18}"

"Me" "......"

"Clara" "The weather's this nice and you're cooped up inside reading novels?"

"Me" "Let me confirm something first."

"Clara" "Go ahead."

"Me" "That window was locked, wasn't it?"

"Clara" "Huh? There was a lock?{change:Clara,face=confused}{bounce:Clara,1,10,0.18}"

"Me" "There was."

"Clara" "Didn't it just slide right open?"

"Me" "That's generally called breaking in."

# Clara hops lightly off the windowsill
actor change Clara face=neutral
"Clara" "Vice President, your definitions are way too conservative.{bounce:Clara,1,30,0.18}"

"Me" "My definitions of the law are also fairly conservative."

"Clara" "This is a clubroom."

"Me" "So breaking into your own club's window makes you a detective?"

"Clara" "Maintaining my edge."

"Me" "Don't frame criminal preparation like it's a morning workout!{speed:45}"

play bgm easygoing

"" "Clara shut the window behind her, her movements so practiced it was hard to believe she actually knew what a \"lock\" was."
"" "Tsukimori Academy has a long history. The old building's exterior still has many pipes and drainage fixtures from a renovation years ago. For ordinary students, that's just part of the nostalgic architecture."
"" "But... for Clara, that was just part of her daily commute."
"" "Clara dragged a chair to the desk and, as she sat down, casually plucked the bookmark from my book to inspect it."

"Me" "Give that back."

"Clara" "Vice President, using a bookmark halfway through a mystery novel is a betrayal of your memory."

"Me" "You put your phone in the fridge yesterday."

"Clara" "......That was to test a locked room."

"Me" "And the result?"
play bgm waiting
"Clara" "The phone cooled down.{change:Clara,face=smirk}"

"Me" "Impressive."

# Scene 1-2: Club Activities Without a Case
scene_break test_room fade
play bgm easygoing
"" "Clara sat down without a shred of propriety and reached for the request box."

actor show Clara face=neutral at 1
"Clara" "Any requests today?"

"Me" "No."

"Clara" "Check again."

"Me" "I just checked."

"Clara" "Then you checked too fast. Requests are all about destiny."

"Me" "I turned the request box upside down, and a crumpled note fell out."
"" "I unfolded the note."

"Me" "A strange shadow has recently appeared on the exterior wall of the dormitory. Requesting the Mystery Club's assistance in confirming the truth."

# Clara blinked

"Me" "What's your take on this, our esteemed Twilight Moon Monkey?"
actor change Clara preset:dir_left|face=happy

"Clara" "What! I climb there every day and I've never seen any shadow!{bounce:Clara,1,10,0.18}"

"Me" "The key issue is why you're climbing there every day."

"Clara" "To verify the rumor."

"Me" "The rumor only started after you started climbing."

"Clara" "Then the rumor just can't keep up with reality.{change:Clara,preset:dir_left|face=happy}"

"Me" "Keep talking and the disciplinary committee will be the one keeping up with you."

# Clara stuffed the note back into the request box

"Clara" "Since there's no official request, today is a rest day."

"Me" "Every day is a rest day for you."

"Clara" "Detectives need breathing room."

"Me" "You need to catch up on homework."

"" "Clara didn't hear me. Or rather, she pretended not to hear."
"" "She slumped onto the desk, pulled out her phone, and started scrolling."
"" "I went back to my novel."

"" "Come to think of it, how does this club even exist? It barely has any members or activities."
"" "What exactly did the previous president pull to get the Mystery Club to split off from the Literature Club? I still have no idea."
"" "Well, whatever. As long as there's air conditioning, it's fine."
"" "After all, this is what the clubroom is like in the summer heat."
"" "Sunlight, cicadas, air conditioning, novels. And a golden monkey scrolling through her phone beside me."

# Scene 1-3: The President Gets Serious
scene_break test_room fade

"" "Some time later, Clara suddenly looked up."
"" "She stared at her phone screen for two seconds, then placed it face-down on the desk."

actor show Clara face=neutral at 1
"Clara" "Vice President."
play bgm title

"Me" "Hmm?"

"Clara" "Hand me that newspaper."

"Me" "Have you finally decided to care about current events?"

"Clara" "Detectives need intelligence."

"" "I pulled out a newspaper from the stack of recent days and handed it over."
"" "Clara sat up straight with a serious expression, then took a vest from the coat rack. It was still far from proper, but for her, this was practically ceremonial attire."

actor change Clara preset:body_coat|face=happy
"Me" "Wait.{speed:40}"

"Clara" "What?"

"Me" "Why did you suddenly put on that outfit?"

"Clara" "Felt like it."

"Me" "And you picked up a newspaper."

"Clara" "Felt like it."

"Me" "What is this, are you playing detective?"

"Clara" "I am a detective."

"Me" "You were watching short videos just a minute ago."

"Clara" "A modern detective."

"Me" "Fair point, but when it comes to this person, I have my reservations."

"" "Footsteps echoed from the hallway outside the door."
"" "Light, evenly spaced. Shoe soles tapping on the old wooden floor, with a hint of restrained urgency."
"" "Clara tilted her head to listen, then nodded slowly."

"Clara" "Here they come.{change:Clara,face=serious}"

"Me" "What?"

"Clara" "The Disciplinary Committee Chair, Eve."

"" "A gentle knock came at the door."
"" "I looked at Clara."

"" "......Seriously?"

"" "Clara didn't answer. She simply turned a page of the newspaper, as if everything was entirely within her control."
"" "Eve pushed the door open and stepped inside."

actor show Eve cry at 2

"Eve" "E-Excuse me."

"Me" "It really is Eve."

"Clara" "Of course."

# Eve looked at the vest on Clara, then at the newspaper in her hands

"Eve" "Clara, you... today you look just like the photo in the club brochure."

"Clara" "Because today there will be a case."

"Me" "She literally just said today was a rest day."

"Clara" "A detective's rest day gets interrupted by cases. That's just common sense."

# Choice 1: How did Clara figure out it was Eve?

choice "Clara's right, it was the footsteps deduction" -> c1_believe
choice "Clara has another reason" -> c1_doubt

branch c1_believe:
    "Me" "Shoe material, pace rhythm, and force of each step can indeed tell you who someone is."
    "Clara" "Vice President, you've grown."
    "Me" "But coming from you, that sounds suspicious."
    "Clara" "Why?"
    "Me" "Last time you fell asleep in the clubroom, I put an alarm right next to your ear and it rang for five minutes. You didn't wake up."
    "Clara" "That's good sleep quality."
    "Me" "Which means your hearing isn't that sharp."
    "Clara" "A detective shuts down irrelevant senses while sleeping."
    "Me" "Then how did you just turn yours on?"
    "Clara" "The scent of a case."
    "Eve" "F-Footsteps have a scent too?"
    "Me" "They don't. Let's move on."
    "Me" "You said the name when the footsteps were still far away. At that distance, the corridor echoes would blend together. You couldn't have heard that precisely."
    jump_branch c1_reveal

branch c1_doubt:
    "Me" "No, that's not it."
    "Clara" "Hmm?"
    "Me" "What you said just now, about shoe material, pace rhythm, force of each step -- I won't deny you might be able to hear all that."
    "Clara" "Might?"
    "Me" "But you made the call before Eve even reached the door. At that point the footsteps were still far away, mixing with the corridor echoes. You couldn't have picked out that many details at that distance."
    "Clara" "My hearing is excellent."
    "Me" "Your hearing isn't that good."
    "Clara" "How would you know?"
    "Me" "Because last time you fell asleep in the clubroom, I put an alarm right next to your ear and it rang for five minutes. You didn't wake up."
    "Clara" "......"
    jump_branch c1_reveal

branch c1_reveal:
    "Me" "Also, you suddenly checked your phone, and only then did you get dressed, grab the newspaper, and sit up straight."
    "Clara" "Vice President."
    "Me" "What?"
    "Clara" "People who are too perceptive end up with no friends."
    "Me" "People who enter through windows do too."

    "" "Eve raised her hand, looking like she wanted to explain."

    "Eve" "I-I sent Clara a message ahead of time. Saying I had something I wanted to consult the Mystery Club about.{change:Eve,neutral}"

    "Clara" "This is intelligence warfare."

    "Me" "That's called receiving a text message."

    "Clara" "Modern intelligence warfare."

    "" "Eve looked at us, seeming like she wanted to laugh, but quickly composed herself."
    "" "She turned to me and tilted her head slightly."

    "Eve" "Come to think of it... what should I call this person? I-I think we've met a few times before, but we haven't been properly introduced."

    "" "Clara spoke without a moment's hesitation."

    "Clara" "My Watson.{change:Clara,preset:dir_left|face=happy}"

    "Me" "Who's Watson?"

    "Clara" "Every detective has an assistant. You're the Vice President, so you're Watson."

    "Me" "And what does that make you, Holmes?"

    "Clara" "Are you silly? I'm Clara, obviously.{bounce:Clara,1,10,0.18}"

    "Me" "Huh?"

    "" "Eve nodded, her expression perfectly earnest."

    "Eve" "Understood, Mr. Watson. P-Please take care of me.{change:Eve,smile}"

    "Me" "......Don't listen to her so seriously."

    "" "Eve let out a soft laugh, then composed herself again."

    "Eve" "Sorry. What I'm about to say next... is very important.{change:Eve,neutral}"
    play bgm anecdote

    # Clara folds up the newspaper

    "Clara" "Then let's officially begin.{change:Clara,preset:body_coat|face=happy}"

    "Me" "When she said that, she actually did look a bit like a club president."
    "" "Provided I forget the fact that she climbed in through a window ten minutes ago."

    jump_id chapter2 erase
