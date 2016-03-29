
Yet Another 'From Scratch' JSON Parser

Note:

1)	In molti predicati vi è l'utilizzo di altri predicati
	negati. Poichè nell'help di Prolog c'è scritto che il
	predicato not/1 è solo per compatibilità con codice
	legacy, io ho utilizzato come suggerito dall'help
	il predicato \+/1

2)	write-companion/3 serve per reinserire in fase di
	scrittura su file il backslash rimosso in fase di parsing
	da parse_string/5 prima degli apici presenti tra i
	caratteri di una stringa.

3)	remove_duplicates/3 è un predicato accessorio a parse_member
	il quale rimuove da una lista data List tutti i duplicati
	di Pair tranne l'ultimo della lista. La nuova lista viene
	uguagliata a Res. Questo predicato serve per come punto di
	ingresso per remove_duplicates/4

4)	skip-whitespaces/2 è recuperato dal file di esempio di un parser
	e modificato per rimuovere ulteriori caratteri 'inutili'.

5)	remove-last/2 rimuove l'ultimo elemento di una lista, viene
	utilizzato da write_values e write_pairs per rimuovere
	l'ultima virgola in un array o in un oggetto dalla lista dei
	caratteri che verrà stampata su un file.

6)	find_pair/3 è un predicato accessorio a jsonget/2 necessario
	per trovare in un oggetto json il pair con la key richiesta.

7)	- parse_element/3 è un punto di ingresso per parse_element/4
	- parse_member/3 è un punto di ingresso per parse_member/4
	- parse_string/3 è un punto di ingresso per parse_string/5
	- parse_identifier/3 è un punto di ingresso per parse_identifier/4
	- parse_number/3 è un punto di ingresso per parse_number/4
	- parse_float/4 viene chiamata da parse_number/4 per effettuare
	  il parsing della parte decimale di un numero

8)	Le funzioni sono scritte con la seguente logica in mente:

	- jsonparse/2 si occupa  di generare la lista dei codici
	  ASCII da una stringa. Tutti gli altri predicati del parser
	  che riconoscono la grammatica vengono chiamati da esso
	  ricorsivamente prendendo in input una lista di caratteri
	  List ed unificando TBD con la lista dei caratteri
	  rimanenti e Res con il valore appena parsato.

	- jsonload/2 viene chiamato per parsare un file e legge una
	  stringa dal file che viene poi data in input a jsonparse
	  per procedere con il parsing.

	- jsonwrite/2 si occupa di aprire un file in scrittura e di
	  chiamare poi ricorsivamente i predicati di writing su file
	  che ricevono in ingresso un oggetto o un array json ed
	  unificano Done con la lista degli oggetti trasformati in
	  caratteri, mentre Res verrà unificato alla fine con la lista
	  completa dei caratteri da scrivere su file.

	- jsonget/2 è un predicato ricorsivo che fa uso del predicato
	  find_pair/3.

