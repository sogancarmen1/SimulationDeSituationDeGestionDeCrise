/**
* Name: model_sgc5
* Based on the internal empty template. 
* Author: Carmen
* Tags: 
*/


model model_sgc5

/* Insert your model definition here */

global {
	float radius_catastrophe <- 40.0;
	point center_catastrophe <- {0, 0};
	float distance_to_intercept <- 20.0;
	int number_of_temoin <- 20;
	int number_of_superObservateur <- 1;
	int number_of_coordinateur <- 1;
	int number_of_secouriste <- 21;
	//Inclusion d'un fichier csv pour pouvoir délimiter la zone de catastrophe qui est en rouge.
	file my_file <- csv_file("../includes/data.csv",",");
	file roads_shapefile <- file("../includes/roads.shp");
	file buildings_shapefile <- file("../includes/buildings.shp");
	geometry shape <- envelope(roads_shapefile);
	graph road_network;
	
	init {
		create temoin number:number_of_temoin {
			location <- any_location_in(one_of(building));
		}
		create superObservateur number:number_of_superObservateur {
			location <- any_location_in(one_of(building));
		}
		create Coordinateur number:number_of_coordinateur {
			location <- any_location_in(one_of(building));
		}
		create Secouriste number:number_of_secouriste {
			location <- any_location_in(one_of(building));
		}
		//Code pour représenter l'espace utilisé en arrière plan
		matrix data <- matrix(my_file);
        ask espace {
            grid_value <- float(data[grid_x,grid_y]);
            color <- (grid_value = 1) ? #red : #cyan;
       }
		create road from: roads_shapefile;
		road_network <- as_edge_graph(road);
		create building from: buildings_shapefile;
	}
}

species road {
    aspect geom {
		draw shape color: #black;
    }
    
    aspect geom3D {
		draw line(shape.points, 2.0) color: #black;
	}
}

species building {
    aspect geom {
		draw shape color: #gray;
    }
    
    aspect geom3D {
		draw shape depth: 20 #m border: #black texture:["../includes/roof_top.jpg","../includes/texture.jpg"];
	}
}

grid espace width: 100 height: 100 neighbors: 4 {
	float grid_value;
}

//Définition de l'espece témoin.
species temoin skills:[moving] {
	bool is_present <- false;
	bool has_observed <- false;
	bool has_reported <- false;
	string rapportDeSituation <- nil;
	string etat_des_lieux <- 'Etats des lieux';
	string rapport_a_envoyer <- nil;
	float speed <- (2 + rnd(3)) #km/#h;
	point target;
//	agent Coordinateur;



	reflex stay when: target = nil {
		if flip(0.05) {
			target <- any_location_in (one_of(building));
		}
	}
	
	reflex move when: target != nil{
		do goto target:target on: road_network;
		if (location = target) {
			target <- nil;
		} 
	}
	
	reflex ConstaterCatastrophe {
		do wander;
		if(location.x <= 50 and location.y <= 85) {
			is_present <- true;
        	has_observed <- true;
		}
		speed <- 0.5;
    }
    
    string ProduireRapport(string etatDesLieux) {
        if (is_present = true and has_observed = true) {
        	rapportDeSituation <- "Ce qui se passe dans la zone de crise";
        }
        return rapportDeSituation;
    }
    
    reflex envoyerRapport {
		rapport_a_envoyer <- ProduireRapport(etat_des_lieux);
        if (rapport_a_envoyer != nil) {
            ask Coordinateur {
                add myself.rapport_a_envoyer to:rapport_temoin;
            }
            has_reported <- true;
        }
    }
    
    //Aspect visuel du témoin
	aspect base {
		draw circle(20) size:5
		at: location + {0, 0, 7} rotate: heading -90 color: #blue;
//		draw circle(50) color: #blue;
		if(is_present and has_observed and has_reported) {
//			draw circle(50) color: #yellow;
			draw circle(20) size:5
			at: location + {0, 0, 7} rotate: heading -90 color: #yellow;
		}
	}
	
	aspect geom3D {
		if target != nil {
			draw obj_file("../includes/people.obj", 90::{-1,0,0}) size: 5
			at: location + {0,0,7} rotate: heading - 90 color: has_reported ? #red : #green;
		}
	}
}

//Définition du coordinateur
species Coordinateur skills:[moving] {
	bool analysed_rapport_temoin <- false;
    bool has_initialized_process <- false;
    bool has_allocated_resources <- false;
    bool has_concluded_process <- false;
    list<string> rapport_temoin <- nil;
    bool values <- false;
    string ordreAffectation <- "Vous êtes affecté";
    list<string> tacheAFaire <- ["tache1", "tache2"];
    float statutCrise  <- 100.0;
    string recept <- '';
    superObservateur super_observateur;
    list<string> mission_de_crise <- nil;
    list<string> rapport_des_secouristes <- nil;
    list<string> les_taches <- nil;
    list<Secouriste> secouristee;
    list<string> recup <- nil;
    float value_process <- 0.0;
    list<string> rapportSecouriste <- nil;
    point target;
    
    init {
    	location <- {80, 50};
    }
    
    reflex stay when: target = nil {
		if flip(0.05) {
			target <- any_location_in (one_of(building));
		}
	}
	
	reflex move when: target != nil{
		do goto target:target on: road_network;
		if (location = target) {
			target <- nil;
		} 
	}
    
    reflex analyserRapportTemoin {
    	//Traitement à faire
    	if(rapport_temoin != nil) {
    		analysed_rapport_temoin <- true;
    	}
    }
    
    reflex initialiserProcessus {
    	has_initialized_process <- true;
    }
    
    string affecterSuperObservateur (superObservateur superObservateurChoisi) {
    	ask superObservateur {
           add true to:is_affected;
        }
        return ordreAffectation;
    }
    
    //Peut être revenir sur l'affaire de liste de tâche
    list<string> distribuerTaches(list<Secouriste> secouriste, string tache) {
    		ask Secouriste {
    			add tache to:taches;
    			myself.recup <- taches;
    		}
    	return recup;
    }
    
    reflex allouerRessources {
    	has_allocated_resources <- true;
    }
    
    float evaluerProcessus (list<string> rapportsDesSecouristes) {
    	//Traitement du rapport
    	loop while: statutCrise > 0 {
    		statutCrise <- statutCrise - 10.0;
    	}
    	return statutCrise;
    }
    
    reflex conclureProcessus {
    	recept <- affecterSuperObservateur(super_observateur);
    	les_taches <- distribuerTaches(secouristee, "taches1");
    	value_process <- evaluerProcessus(rapportSecouriste);
    	if(value_process = 0) {
    		has_concluded_process <- true;
    	}
    }
    
    // Aspect visuel du Coordinateur
    aspect base {
        draw triangle(50) color:#black;
        if(recup != nil) {
        	ask Secouriste at_distance(distance_to_intercept){
        		draw polyline([self.location, myself.location]) color:#black;
        	}
        }
    }
    
    aspect geom3D {
		if target != nil {
			draw obj_file("../includes/people.obj", 90::{-1,0,0}) size: 5
			at: location + {0,0,7} rotate: heading - 90 color: has_concluded_process ? #yellow : #black;
		}
	}
}

species superObservateur skills:[moving] {
	list<bool> is_affected <- nil;
	bool has_received_order <- false;
	bool is_on_site <- false;
	bool has_observed <- false;
	bool has_identified_tasks <- false;
	bool has_defined_missions <- false;
	point target;
	
	init {
		location <- {60, 95};
	}
	
	reflex stay when: target = nil {
		if flip(0.05) {
			target <- any_location_in (one_of(building));
		}
	}
	
	reflex move when: target != nil{
		do goto target:target on: road_network;
		if (location = target) {
			target <- nil;
		} 
	}
	
	//Ici il reçoit l'ordre du coordinateur
	string RecevoirOrdreduCoordonnateur(list<bool> instructionDuCoordinateur) {
		if(instructionDuCoordinateur != nil) {
			return "Ordre reçu";
		}
    }
    
    //Atterissage sur les lieux du coordinateur après avoir reçu l'ordre du coordinateur.
    reflex AllersurlesLieux {
        if (RecevoirOrdreduCoordonnateur(is_affected) != '') {
        	location <- {20, 35};
            is_on_site <- true;
        }
    }
    
    //Reflex pour observation de la situation
    reflex ObserverSituation {
        if (is_on_site = true) {
            has_observed <- true;
        }
    }
	
	//Reflex pour identifier les tâches necessaires
	reflex IdentifierTachesNecessaires {
        if (has_observed = true) {
            has_identified_tasks <- true;
        }
    }
    
    //Définir mission
    string DefinirMissionsdeCrise (string value) {
        if (has_identified_tasks = true) {
            return 'mission de crise';
        }
    }
    
    //Reflex pour présenter une mission de crise
    reflex presenterMissionsDeCrise {
    	string valueObtain <- DefinirMissionsdeCrise("Résultats des observations sur le terrain");
    	if(valueObtain != nil) {
    		ask Coordinateur {
    			add valueObtain to:mission_de_crise;
    		}
    		has_defined_missions <- true;
    	}
    }
    
    //Aspect visuel pour le superCoordinateur
    aspect base {
    	draw square(50) color: #gray;
    	if(has_defined_missions) {
    		draw square(50) color: #gray;
    	}
    }
    
    aspect geom3D {
		if target != nil {
			draw obj_file("../includes/people.obj", 90::{-1,0,0}) size: 5
			at: location + {0,0,7} rotate: heading - 90 color: has_defined_missions ? #gray : #orange;
		}
	}
}

species Secouriste skills:[moving] {
    bool has_received_tasks <- false;
    bool has_executed_tasks <- false;
    bool has_produced_report <- false;
    list<string> taches <- nil;
    string value <- '';
    string values <- "";
    string valuess <- "";
    bool is_true_or_false;
    bool oneValue <- false;
    bool twoValue <- false;
    int compte <- 0;
    point target;
    
    init {
    }
    
    reflex stay when: target = nil {
		if flip(0.05) {
			target <- any_location_in (one_of(building));
		}
	}
	
	reflex move when: target != nil{
		do goto target:target on: road_network;
		if (location = target) {
			target <- nil;
		} 
	}
    
     reflex update {
		ask Coordinateur {
		    // statements
		}
    }
    
    reflex moving {
		do wander;
		if(location.x <= 95 and location.y <= 75) {
			oneValue <- true;
			if(location.x <= 50 and location.y <= 85) {
				twoValue <- true;
			}
		}
//		compte <- compte + 1;
	}

    string RecevoirTaches (list<string> tache) {
    	if(tache != nil) {
    		return 'Taches reçu';
    	}
    }
    
    string ExecuterTaches (list<string> tache) {
    	value <- RecevoirTaches(taches);
    	if(value = 'Taches reçu') {
    		if(location.x <= 50 and location.y <= 85) {
				has_executed_tasks <- true;
			}
    		if(has_executed_tasks = true) {
    			return "succes";
    		}
    	}
    	return "echec";
    }
    
    bool ProduireRapport(string valueStatutTache) {
    	if(valueStatutTache = 'succes'){
    		ask Coordinateur {
    			add "rapport fait" to:rapportSecouriste;
    		}
    		return true;
    	}
        return false;
    }
    
    reflex excutionAction {
    	values <- RecevoirTaches(taches);
    	valuess <- ExecuterTaches(taches);
    	is_true_or_false <- ProduireRapport(valuess);
    	if(is_true_or_false) {
    		has_produced_report <- true;
    	}
    }
    
    //Aspect visuel pour le Secouriste
    aspect base {
        draw circle(50) color:#black;
        draw triangle(50) color:#white;
        if(oneValue) {
        	draw circle(50) color:#black;
        	draw triangle(50) color:#red;
        	if(twoValue) {
        		draw circle(50) color:#black;
        		draw triangle(50) color:#green;
        		//Aspect visuel lorsque le secouriste envoie un rapport stipulant qu'il a fini sa tâche
        		if(is_true_or_false) {
        			ask Coordinateur {
        				draw polyline([self.location, myself.location]) color:#red;
        			}
        		}
        		if(length(Secouriste where (each.has_produced_report = true)) = 21) {
        			ask Coordinateur {
        				draw triangle(50) color:#green;
        			}
        		}
        	}
        }
    }
    
    aspect geom3D {
		if target != nil {
			draw obj_file("../includes/people.obj", 90::{-1,0,0}) size: 5
			at: location + {0,0,7} rotate: heading - 90 color: has_produced_report ? #brown : #blue;
		}
	}
}


experiment my_experiment type:gui {
	parameter "number of temoin" var:number_of_temoin;
	parameter "number of superObservateur" var:number_of_superObservateur;
	parameter "number of coordinateur" var:number_of_coordinateur;
	parameter "number of secouriste" var:number_of_secouriste;
	output {
		monitor "Nombre de Témoins ayant rapporté" value: length(temoin where (each.has_reported = true));
		monitor "Nombre de Super observateur ayant défini des missions" value: length(superObservateur where (each.has_defined_missions = true));
		monitor "Nombre de Coordinateurs ayant conclu le processus" value: length(Coordinateur where (each.has_concluded_process = true));
		monitor "Nombre de Secouriste ayant produit un rapport" value: length(Secouriste where (each.has_produced_report = true));
		display my_display {
			grid espace;
			species road aspect: geom;
	    	species building aspect: geom;
			species temoin aspect:base;
			species superObservateur aspect:base;
			species Coordinateur aspect:base;
			species Secouriste aspect:base;
		}
		display my_chart {
			chart "Actions émises par les agents" {
				data "Témoins ayant rapporté" value: length(temoin where (each.has_reported = true));
				data "Super observateur ayant défini des missions" value: length(superObservateur where (each.has_defined_missions = true));
				data "Coordinateurs ayant conclu le processus" value: length(Coordinateur where (each.has_concluded_process = true));
				data "Secouristes ayant produit un rapport" value: length(Secouriste where (each.has_produced_report = true));
			}
		}
		display view3D type: 3d antialias: false {
			light #ambient intensity: 80;
			image "../includes/luneray.jpg" refresh: false; 
			species building aspect: geom3D refresh: false;
			species road aspect: geom3D refresh: false;
			species temoin aspect: geom3D;
			species superObservateur aspect:geom3D;
			species Coordinateur aspect:geom3D;
			species Secouriste aspect:geom3D;
		}
	}
	init {
        create road from: roads_shapefile;
        create building from: buildings_shapefile;
    }
}