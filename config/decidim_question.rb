Decidim::QuestionCaptcha.configure do |config|
    config.questions = {
      fr: [
        { "question" => "Quelle est la capitale de la France ?", "answers" => "Paris,paris,PARIS" },
        { "question" => "De quelle couleur est le chat noir ?", "answers" => "noir,Noir,NOIR" },
        { "question" => "Quel est le numéro de département de la Loire-Atlantique ?", "answers" => "44,quarante quatre,Quarante-quatre,QUARANTE-QUATRE" },
        { "question" => "Quelle est la seconde couleur de la liste : langue, gris, orange", "answers" => "orange,Orange,ORANGE" },
        { "question" => "Quel est le nombre le plus grand entre les nombres suivants : 18, cinq, quarante, cent", "answers" => "cent,100,Cent,CENT" },
        { "question" => "Parmi 50, soixante-seize, vingt-trois, un, 28 ou 77, lequel est le plus grand ?", "answers" => "77	soixante dix sept,soixante-dix-sept,Soixante-dix-sept" },
        { "question" => "14, trente-cinq ou quarante-cinq : le plus petit est ?", "answers" => "14,quatorze,Quatorze" },
        { "question" => "Si les cheveux sont noirs, de quelle couleur sont les cheveux ?", "answers" => "noirs,noir,Noir,Noirs,NOIR,Noirs" },
        { "question" => "Rose, vert et coude : combien de couleurs dans la liste ?", "answers" => "2,deux,Deux,DEUX" },
        { "question" => "Dans la liste suivante lequel n'est pas un continent: Afrique, Asie, Italie ?", "answers" => "italie,l'italie,litalie" },
        { "question" => "Dans la liste suivante lequel est un verbe : marcher, vache, cavalier ?", "answers" => "marcher" },
        { "question" => "On respire par : le nez, l'oreil, les cheveux ?", "answers" => "nez,le nez,lenez" },
        { "question" => "Dans quelle ville se trouve la Tour Eiffel ?", "answers" => "paris,a paris,à paris" },
        { "question" => "La liste bleu, doigt, rose, fromage, œil et pain contient combien de couleurs ?", "answers" => "2,deux,Deux,DEUX" }
        { "question" => "De quelle couleur est le cheval gris?", "answers" => "gris" }
        { "question" => "Êtes-vous une machine?", "answers" => "non" }
        { "question" => "Quelle est la première couleur de la liste : langue, gris, orange ?", "answers" => "gris" }
        { "question" => "Quelle est la troisième lettre du mot lait ?", "answers" => "i" }
        { "question" => "Confiture, bras, doigt, éléphant : combien y a-t-il de parties du corps ?", "answers" => "2, deux" }
        { "question" => "Combien de lettre compte-t-on dans l'alphabet ?", "answers" => "26, vingt-six" }
        { "question" => "Parmis les animaux suivants lequel produit du lait : cigale, vache, corbeau ?", "answers" => "vache, la vache" }
        { "question" => "Dans la liste suivante lequel n'est pas un moyen de transport: métro, nuage, train ?", "answers" => "nuage, le nuage" }

      ],
      en: [
        { "question" => "What is the capital of France?", "answers" => "Paris,paris,PARIS" },
        { "question" => "What color is the black cat?", "answers" => "black,BLACK" },
        { "question" => "What is the second color in the list: language, gray, orange", "answers" => "orange,ORANGE" },
        { "question" => "Which of the following numbers is greater: 18, five, forty, one hundred", "answers" => "one hundred,100,ONE HUNDRED" },
        { "question" => "Which of 50, seventy-six, twenty-three, one, 28, or 77 is greater?", "answers" => "77 seventy-seven,Seventy-seven,Seventy-seven" },
        { "question" => "14, thirty-five or forty-five: which is smaller?", "answers" => "14,fourteen,Fourteen" }
        { "question" => "If the hair is black, what color is the hair?", "answers" => "black,black,black" },
        { "question" => "Pink, green and elbow: how many colors in the list?", "answers" => "2,two,TWO" },
        { "question" => "In the following list which one is not a continent: Africa, Asia, Italy?", "answers" => "italy,italy,italy" },
        { "question" => "In the following list which one is a verb: walk, cow, rider?", "answers" => "walk" },
        { "question" => "Which of the following is a verb: nose, ear, hair?", "answers" => "nose,lenez" },
        { "question" => "In which city is the Eiffel Tower located?", "answers" => "paris,a paris,à paris" },
        { "question" => "The list blue, finger, pink, cheese, eye and bread contains how many colors?", "answers" => "2,two,TWO" }
        { "question" => "What color is the gray horse?", "answers" => "gray" }
        { "question" => "Are you a machine?", "answers" => "no" }
        { "question" => "What's the first color in the list: language, gray, orange?", "answers" => "gray" }
        { "question" => "What is the third letter in the word milk?", "answers" => "i" }
        { "question" => "Jam, arm, finger, elephant: how many body parts are there?", "answers" => "2, two" }
        { "question" => "How many letters are in the alphabet?", "answers" => "26, twenty-six" }
        { "question" => "Which of the following animals produces milk: cicada, cow, crow?", "answers" => "cow, the cow" }
        { "question" => "Which of the following is not a means of transportation: subway, cloud, train?", "answers" => "cloud, the cloud" }
      ]
    }
  end