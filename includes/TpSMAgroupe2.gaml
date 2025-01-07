model TpSMAgroupe2

global { 
 // Chemin des fichiers shapefile
 file habitation_shapefile <- file("C:/Users/ibrahim/Gama_Workspace/TpSmaGroupe1/models/buildings.shp");
 file hospital_shapefile <- file("C:/Users/ibrahim/Gama_Workspace/TpSmaGroupe1/models/hopitaux.shp");
 file road_shapefile <- file("C:/Users/ibrahim/Gama_Workspace/TpSmaGroupe1/models/roads.shp");
 file control_center_shapefile <- file("C:/Users/ibrahim/Gama_Workspace/TpSmaGroupe1/models/centre.shp");

 // Définition de l'enveloppe de la simulation
 geometry shape <- envelope(habitation_shapefile);
 geometry free_space;

 // Nombre d'ambulances et patients transportés
 int nb_ambulances <- 5;
 int patients_transported <- 0; // Compteur de patients transportés
 int max_patients <- 10; // Nombre maximum de patients à transporter pour terminer la simulation

 // Paramètres pour ajuster la taille des objets
 float habitation_size <- 0.5 parameter: "Taille des habitations" category: "Taille" min: 0.10 max: 1.0;
 float hospital_size <- 50.0 parameter: "Taille des hôpitaux" category: "Taille" min: 1.0 max: 5.0;
 float road_size <- 1.5 parameter: "Taille des routes" category: "Taille" min: 0.5 max: 3.0;
 float control_center_size <- 50.0 parameter: "Taille du centre de contrôle" category: "Taille" min: 5.0 max: 10.0;
 float ambulance_size <- 100.0 parameter: "Taille des ambulances" category: "Taille" min: 1.0 max: 5.0;

 init { 
  free_space <- copy(shape);
  create habitation from: habitation_shapefile {
    shape <- shape buffer habitation_size; // Ajustez le facteur de buffer selon vos besoins
  }
  create hospital from: hospital_shapefile {
    shape <- shape buffer hospital_size; // Ajustez le facteur de buffer selon vos besoins
  }
  create road from: road_shapefile {
    shape <- shape buffer road_size; // Ajustez le facteur de buffer selon vos besoins
  }
  create control_center from: control_center_shapefile {
    shape <- shape buffer control_center_size; // Ajustez le facteur de buffer selon vos besoins
  }
  create ambulance number: nb_ambulances {
   location <- any_location_in(free_space);
   target_loc <- nil; // Initialisation de target_loc
   hospital_loc <- location; // Initialisation de hospital_loc à l'emplacement de l'ambulance
   patient_loc <- nil; // Initialisation de patient_loc
  }
 } 
}

// Définition de l'espèce habitation
species habitation {
 aspect default {
  // Dessin de la forme des habitations en jaune avec mise à l'échelle
  draw shape color: #grey; // Ajustez l'échelle selon vos besoins
 }
}

// Définition de l'espèce hôpital
species hospital {
 aspect default {
  // Dessin de la forme des hôpitaux en bleu avec mise à l'échelle
  draw shape color: #blue; // Ajustez l'échelle selon vos besoins
 }
}

// Définition de l'espèce route
species road {
 aspect default {
  // Dessin de la forme des routes en noir avec mise à l'échelle
  draw shape color: #black; // Ajustez l'échelle selon vos besoins
 }
}

// Définition de l'espèce centre de contrôle
species control_center {
 aspect default {
  // Dessin de la forme du centre de contrôle en orange avec mise à l'échelle
  draw shape color: #orange; // Ajustez l'échelle selon vos besoins
 }
}

// Définition de l'espèce ambulance avec la compétence de mouvement
species ambulance skills: [moving] {
 // Déclaration de la vitesse de l'ambulance
 float speed <- 1.0 + rnd(500) / 1000;
 // Déclaration de la variable de localisation cible
 point target_loc;
 // Déclaration de la variable de localisation de l'hôpital
 point hospital_loc;
 // Déclaration de la variable de localisation du patient
 point patient_loc;
 // Déclaration de la variable d'état de l'ambulance (si elle transporte un patient ou non)
 bool has_patient <- false;

 // Réflexe pour recevoir les ordres du centre de contrôle
 reflex receive_order {
  // Si l'ambulance est à l'hôpital et ne transporte pas de patient
  if (location distance_to hospital_loc < 2 and not has_patient) {
    // Le centre de contrôle donne un ordre avec une nouvelle localisation cible pour récupérer un patient
    patient_loc <- any_location_in(free_space);
    target_loc <- patient_loc; // Aller chercher le patient
    write "Ambulance reçoit l'ordre de récupérer un patient à " + patient_loc;
  }
 }

 // Réflexe pour le déplacement de l'ambulance
 reflex move {
  // Vérification que la localisation cible n'est pas nulle
  if (target_loc != nil) {
    // Sauvegarde de l'ancienne localisation
    point old_location <- copy(location);
    // Déplacement vers la nouvelle cible en fonction de la vitesse
    do goto target: target_loc;
    // Vérification que l'ambulance reste dans l'espace libre
    if not (self overlaps free_space) {
     // Correction de la position pour rester dans l'espace libre
     location <- (location closest_points_with free_space)[1];
    }
    // Mise à jour de la vitesse en fonction de la distance parcourue
    speed <- location distance_to old_location;

    // Si l'ambulance atteint la cible et transporte un patient
    if (location distance_to target_loc < 2) {
      if (has_patient) {
        // Arrivée à l'hôpital
        write "Ambulance arrive à l'hôpital avec le patient.";
        has_patient <- false; // Déposer le patient
        target_loc <- nil; // Réinitialiser la cible
        patients_transported <- patients_transported + 1; // Incrémenter le compteur de patients transportés
      } else {
        // Arrivée chez le patient
        write "Ambulance récupère le patient à " + location;
        has_patient <- true; // Récupérer le patient
        target_loc <- hospital_loc; // Retourner à l'hôpital
      }
    }
  }
 }

 aspect default {
  // Changement de couleur en fonction de l'état de l'ambulance
  draw circle(ambulance_size) color: (has_patient ? #green : #red);
 }
}

// Définition de l'expérience de simulation GUI
experiment TpSMAgroupe2 type: gui {
 // Paramètre pour le nombre d'ambulances avec des valeurs min et max
 parameter "Number of ambulances" var: nb_ambulances min: 1 max: 20;

 output {
  display map type: opengl {
   // Affichage des différentes espèces sur la carte
   species habitation;
   species ambulance;
   species hospital;
   species road;
   species control_center;
  }
 }
}
