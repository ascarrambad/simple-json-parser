
Yet Another 'From Scratch' JSON Parser

Note:

1)	write-companion serve per reinserire in fase di
	scrittura su file il backslash rimosso in fase di parsing
	da parse-string-i prima degli apici presenti tra i
	caratteri di una stringa.

2)	evaluate-pair è una funzione accessoria alla funzione
	standard del Common Lisp remove-duplicates, necessaria
	per valutare l'uguaglianza delle key dei pair presenti
	in un jsonobj.

3)	del-whitespaces è una funzione che elimina da una
	stringa passatagli qualsiasi spazio, tab, return o
	endline, fatta eccezione per i caratteri presenti tra due apici.

4)	flatten è una funzione presa dalle slide del corso
	utilizzata in jsonwrite.

5)	Qualsiasi funzione il cui nome termina con "-i" viene
	utilizzata ricorsivamente da un altra che è il punto di
	ingresso della funzione.

6)	parse-floatb viene chiamata da parse-number-ib per effettuare
	il parsing della parte decimale di un numbero.

7)	Le funzioni sono scritte con la seguente logica in mente:

	- jsonparse si occupa  di generare la lista dei caratteri
	  da una stringa. Tutte le altre funzioni del parser che
	  riconoscono la grammatica vengono chiamate da essa
	  ricorsivamente prendendo in input una lista l di caratteri e
	  restituiscono in output il valore appena parsato e la
	  lista dei caratteri rimanenti.

	- jsonload viene chiamata per parsare un file e legge
	  un carattere alla volta. Ottenuta la lista completa
	  dei caratteri presenti in un file viene chiamata
	  jsonparse per procedere con il parsing.

	- jsonwrite si occupa di aprire un file in scrittura e di
	  chiamare poi ricorsivamente le funzioni di writing su
	  file che prendono in ingresso una lista rappresentante un
	  oggetto o un array json e restituiscono i caratteri
	  corrispondenti all'oggetto che sono state incaricate
	  di riconoscere.

	- jsonget è una funzione ricorsiva che fa uso della
	  funzione apply per passarsi i propri argomenti ed
	  evitare di avere una lista dentro l'altra nella
	  variabile fields. È arricchita con molti custom-error
	  a seconda dei valori delle variabili json e flds.

