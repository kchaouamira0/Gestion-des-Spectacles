CREATE TABLE SPECTACLE 
	(idSpec INTEGER PRIMARY KEY,
	Titre VARCHAR2 (40) NOT NULL,
    dateS DATE NOT NULL ,
    h_debut NUMBER(4,2) NOT NULL,
    dureeS NUMBER(4,2) NOT NULL,
    nbrSpectateur INTEGER NOT NULL,
    idLieu INTEGER,
	CONSTRAINT chk_spect_durees CHECK (dureeS BETWEEN 1 AND 3),
    CONSTRAINT FK_spect_Lieux FOREIGN KEY(idLieu)REFERENCES Lieu(idLieu)
    );
    

CREATE OR REPLACE TRIGGER trg_check_dateS
  BEFORE INSERT OR UPDATE ON SPECTACLE
  FOR EACH ROW
BEGIN

  IF( :new.dateS <= SYSDATE)
  THEN
    RAISE_APPLICATION_ERROR( -20001, 
          'Invalid date Spectacle: dateS must be greater than the current date - value = ' || 
          to_char( :new.dateS, 'YYYY-MM-DD HH24:MI:SS' ) );
  END IF;
END;

CREATE OR REPLACE TRIGGER trg_check_nbrSpec
  BEFORE INSERT OR UPDATE ON SPECTACLE
  FOR EACH ROW
DECLARE 
cp lieu.capacite%type;
id number;
BEGIN
  id:=:new.idLieu;
  select l.capacite into cp from lieu l where l.idLieu=id ;   
   

  IF( :new.nbrSpectateur > cp)
  THEN
    RAISE_APPLICATION_ERROR(20100,'capacité < nbr de spectateurs');
   END IF;

END;


CREATE TABLE Rubrique
	(
     idRub INTEGER PRIMARY KEY, 
	 idSpec INTEGER NOT NULL, 
	 idArt INTEGER NOT NULL, 
     dateRub DATE NOT NULL ,
	 H_debutR NUMBER(4,2) NOT NULL, 
     dureeRub NUMBER(4,2) NOT NULL, 
     typeRub VARCHAR2(10), 
     CONSTRAINT fk_rub_spect FOREIGN KEY(idSpec) REFERENCES SPECTACLE(idSpec) ON DELETE CASCADE,
     CONSTRAINT fk_rub_art FOREIGN KEY(idArt)  REFERENCES Artiste(idArt) ON DELETE CASCADE ,
     CONSTRAINT ck_typeR check( typeRub IN('comedie','theatre','dance','imitation','magie','musique','chant'))
     );

CREATE OR REPLACE TRIGGER trg_check_dateR_dureeR
  BEFORE INSERT OR UPDATE ON Rubrique
  FOR EACH ROW
DECLARE 
Tdate spectacle.dateS%type;
Tduree spectacle.dureeS%type;
Theure spectacle.h_debut%type;
nbrRub number;
BEGIN
  select count(idSpec) into nbrRub from Rubrique
  where idSpec= :new.idSpec;
  IF (nbrRub =3) 
  THEN RAISE_APPLICATION_ERROR(-20105,'nbr de rubrique atteint');
  END IF;
  select dateS,dureeS,h_debut into Tdate,Tduree,Theure from spectacle
  where spectacle.idSpec=:new.idSpec;
  IF( :new.dateRub <> Tdate)
  THEN
    RAISE_APPLICATION_ERROR(-20100,'la date de la rubrique diff de celle du spectacle');
  END IF;
    IF( :new.H_debutR < Theure)
  THEN
    RAISE_APPLICATION_ERROR(-20101,'l heure de la rubrique >  celle du spectacle');
  END IF;
      IF( :new.dureeRub > Tduree)
  THEN
    RAISE_APPLICATION_ERROR(-20102,'la duree de la rubrique > de celle du spectacle');
  END IF; 
END;

CREATE TABLE BILLET
	(idBillet INTEGER PRIMARY KEY,
	categorie VARCHAR2(10),
	prix NUMBER(5,2) NOT NULL,
	idspec INTEGER NOT NULL ,
	Vendu VARCHAR(3) NOT NULL, 

CONSTRAINT chk_billet_PRIX CHECK(prix BETWEEN 10 AND 300),
CONSTRAINT fk_billet_spec FOREIGN KEY (idspec)REFERENCES spectacle,
CONSTRAINT chk_billet_vendu CHECK(vendu IN ('Oui','Non')),
CONSTRAINT chk_categorie CHECK(categorie IN('gold','silver','normal'))
);

CREATE TABLE CLIENT
      ( idClt INTEGER PRIMARY KEY,
       nomClt VARCHAR(20),
       prenomClt VARCHAR(20),
       tel VARCHAR(8),
       email VARCHAR(50) NOT NULL,
       motP VARCHAR(20) NOT NULL,
       CONSTRAINT chk_valEmail CHECK( regexp_like(email,'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$')),
       CONSTRAINT chk_valTel CHECK( regexp_like(tel,'^[0-9]{8}$'))
);


CREATE OR REPLACE PACKAGE gest_Spectacles IS
procedure ajoutSpectacle(idSpec in spectacle.idSpec%type,
titre in spectacle.titre%type,dateS in  spectacle.dateS%type,
h_debut in spectacle.h_debut%type,dureeS in  spectacle.dureeS%type,nbrSpec in spectacle.nbrSpectateur%type,
idLieu in spectacle.idLieu%type);
procedure annulerSpectacle(idSp spectacle.idSpec%type);
procedure modifierSpectacle(idSp spectacle.idSpec%type,
titreSp spectacle.titre%type,dateSp spectacle.dateS%type,
h_debutSp spectacle.h_debut%type,dureeSp  spectacle.dureeS%type,
nbrSp spectacle.nbrSpectateur%type, idLieuSp spectacle.idLieu%type);
function chercherSpectacle(idSp spectacle.idSpec%type,titre spectacle.titre%type)
RETURN spectacle%ROWTYPE ;
procedure ajoutRubrique(idRub rubrique.idRub%type,idSpec rubrique.idSpec%type,idArt rubrique.idArt%type,
dateRub rubrique.dateRub%type,
h_debutR rubrique.h_debutR%type,dureeRub rubrique.dureeRub%type,typeRub rubrique.typeRub%type);
procedure modifierRubrique(idRb rubrique.idRub%type,
idArtR rubrique.idArt%type,h_debutRb rubrique.h_debutR%type,
dureeRb rubrique.dureeRub%type);
function chercherRubrique(idSpec rubrique.idSpec%type,nomArt artiste.nomArt%type)
RETURN rubrique%ROWTYPE;
procedure supprimerRubrique(idRub rubrique.idRub%type);
END gest_Spectacles;

CREATE SEQUENCE seq_client START WITH 1;
CREATE SEQUENCE seq_artiste START WITH 1;
CREATE SEQUENCE seq_billet START WITH 1;
CREATE SEQUENCE seq_lieu START WITH 1;
CREATE SEQUENCE seq_rubrique START WITH 1;
CREATE SEQUENCE seq_spectacle START WITH 1;

INSERT INTO client values(seq_client.NEXTVAL,'Dridi','Ali','24313180','aligamil.com','123456');
INSERT INTO client values(seq_client.NEXTVAL,'Achour','Asma','25222222','achour@gamil.com','123456');

INSERT INTO lieu values(seq_lieu.NEXTVAL,'cineMadart','Rue Hbib Bourguiba - Monoprix Dermech, Tunisie',
'carthage',866);
INSERT INTO lieu values(seq_lieu.NEXTVAL,'lagora','Rue 1 la marsa','la marsa',603);

INSERT INTO artiste values (seq_artiste.NEXTVAL,'belkadhi','najib','acteur');
INSERT INTO artiste values (seq_artiste.NEXTVAL,'Attia','sarah','chanteur');

SELECT * from artiste;

INSERT INTO spectacle values (seq_spectacle.NEXTVAL,'yyy','24/12/2022',16.00,3,200,1);
INSERT INTO spectacle values (seq_spectacle.NEXTVAL,'zzz','26/12/2022',14.00,3,300,2);
INSERT INTO spectacle values (seq_spectacle.NEXTVAL,'zzz','01/12/2022',14.00,3,300,2);
INSERT INTO spectacle values (seq_spectacle.NEXTVAL,'aaa','27/12/2022',14.00,2,400,2);
select *  from spectacle;
SELECT * from artiste;


INSERT INTO rubrique values(seq_rubrique.NEXTVAL,41,1,'24/12/2022',17.00,2,'dance');
INSERT INTO rubrique values(seq_rubrique.NEXTVAL,19,1,'21/12/2022',16.00,1,'theatre');
INSERT INTO rubrique values(seq_rubrique.NEXTVAL,19,1,'21/12/2022',16.00,1,'musique');
INSERT INTO rubrique values(seq_rubrique.NEXTVAL,19,1,'21/12/2022',16.00,1,'dance');
INSERT INTO rubrique values(seq_rubrique.NEXTVAL,19,1,'21/12/2022',16.00,1,'magie');

INSERT INTO rubrique values(seq_rubrique.NEXTVAL,41,1,'27/12/2022',14.00,5,'magie');



SELECT * from rubrique;



SELECT * from rubrique;

CREATE OR REPLACE PACKAGE BODY gest_Spectacles AS

procedure ajoutSpectacle(idSpec  in spectacle.idSpec%type,
titre in  spectacle.titre%type,dateS in spectacle.dateS%type,
h_debut in spectacle.h_debut%type,dureeS in spectacle.dureeS%type,nbrSpec in spectacle.nbrSpectateur%type,
idLieu in spectacle.idLieu%type) IS
errAjout EXCEPTION;
nbrSp number;
BEGIN 
DBMS_OUTPUT.PUT_LINE('titre');
SELECT count(*) into nbrSp from Spectacle S
where S.idLieu=idLieu and S.h_debut=h_debut and S.dateS=dateS;
IF (nbrSp <> 0) THEN raise errAjout;
END IF;
DBMS_OUTPUT.PUT_LINE('titre');
INSERT INTO SPECTACLE VALUES (idSpec ,titre ,dateS,h_debut ,dureeS  ,nbrSpec ,idLieu );
COMMIT;
EXCEPTION 
WHEN errAjout THEN 
DBMS_OUTPUT.PUT_LINE('lieu pas disponible');
END ajoutSpectacle;

procedure annulerSpectacle(idSp spectacle.idSpec%type) IS
errAnn EXCEPTION;
vidSpec spectacle.idSpec%type;
BEGIN 
SELECT idSpec into vidSpec from SPECTACLE ;
UPDATE SPECTACLE SET dateS=NULL 
WHERE idSpec=idSp;
EXCEPTION 
WHEN NO_DATA_FOUND THEN 
DBMS_OUTPUT.PUT_LINE('spectacle inexistant');
END annulerSpectacle;

 procedure modifierSpectacle(idSp spectacle.idSpec%type,
titreSp spectacle.titre%type,dateSp spectacle.dateS%type,
h_debutSp spectacle.h_debut%type,dureeSp  spectacle.dureeS%type,
nbrSp spectacle.nbrSpectateur%type, idLieuSp spectacle.idLieu%type) IS
errModif EXCEPTION ;
vidSpec spectacle.idSpec%type;
vdateSp SPECTACLE.dateS%type;
heureSp SPECTACLE.h_debut%type;
nbrSpc NUMBER;
BEGIN 
SELECT idSpec into vidSpec from SPECTACLE WHERE idSpec=idSp;
IF(titreSp!=null) then
update spectacle  set titre=titreSp where idSpec=idSp;
commit;
END IF;
IF(dateSp!=null) then
update spectacle  set dateS=dateSp where idSpec=idSp;
commit;
END IF;
IF(h_debutSp!=null) then
update spectacle  set h_debut=h_debutSp where idSpec=idSp;
commit;
END IF;
IF(dureeSp!=null) then
update spectacle  set dureeS=dureeSp where idSpec=idSp;
commit;   
END IF;
IF(nbrSp!=null) then
update spectacle  set nbrSpectateur=nbrSp where idSpec=idSp; 
commit;
END IF; 
IF(idLieuSp!=null) then
select dateS,h_debut into vdateSp,heureSp from spectacle where idSpec=idSp;
SELECT count(*) into nbrSpc from Spectacle S
where S.idLieu=idLieu and S.h_debut=heureSp and S.dateS=dateSp;
IF (nbrSpc <> 0) THEN raise errModif;
ElSE 
update spectacle  set idLieu=idLieuSp where idSpec=idSp; 
commit;
END IF; 
END IF;
EXCEPTION 
WHEN NO_DATA_FOUND THEN 
DBMS_OUTPUT.PUT_LINE('spectacle inexistant');
WHEN errModif THEN 
DBMS_OUTPUT.PUT_LINE('lieu pas disponible');
END modifierSpectacle;

function chercherSpectacle(idSp spectacle.idSpec%type,
titre spectacle.titre%type) RETURN spectacle%ROWTYPE IS 
vSpec spectacle%ROWTYPE;
BEGIN 
select * into vSpec from spectacle s where s.idSpec=idSp or s.titre=titre;
return vSpec;
END chercherSpectacle;

procedure ajoutRubrique(idRub rubrique.idRub%type,idSpec rubrique.idSpec%type,idArt rubrique.idArt%type,
dateRub rubrique.dateRub%type,
h_debutR rubrique.h_debutR%type,dureeRub rubrique.dureeRub%type,typeRub rubrique.typeRub%type)IS 
BEGIN 
INSERT INTO rubrique VALUES (idRub ,idSpec ,idArt,dateRub ,h_debutR ,dureeRub ,typeRub );
END ajoutRubrique;

procedure modifierRubrique(idRb rubrique.idRub%type,
idArtR rubrique.idArt%type,h_debutRb rubrique.h_debutR%type,
dureeRb rubrique.dureeRub%type) IS
vidRub rubrique.idRub%type; 
BEGIN
SELECT idRub into vidRub from RUBRIQUE r WHERE r.idRUB=idRb;
if(idArtR!=null) then
update rubrique  set idArt=idArtR where idRub=idRb;
commit;
end if;
if(h_debutRb!=null) then
update rubrique  set h_debutR=h_debutRb where idRub=idRb;
commit;
end if;
if(dureeRb!=null) then
update rubrique  set dureeRub=dureeRb where idRub=idRb;
commit;
end if;
EXCEPTION 
WHEN NO_DATA_FOUND THEN 
DBMS_OUTPUT.PUT_LINE('rubrique inexistant'); 
END modifierRubrique;

procedure supprimerRubrique(idRub rubrique.idRub%type) IS 
BEGIN 
delete from rubrique r where r.idRub=idRub;
END supprimerRubrique;


function chercherRubrique(idSpec rubrique.idSpec%type,nomArt artiste.nomArt%type)
RETURN rubrique%ROWTYPE IS
vRub rubrique%ROWTYPE;
idAR number:=NULL;
BEGIN 
if (nomArt <> NULL ) THEN 
SELECT idArt into idAR from Artiste  A
where A.nomArt=nomArt;
END IF;
select * into vRub from rubrique R where R.idSpec=idSpec or R.idArt=idArt;
return vRub;
END chercherRubrique;

END gest_Spectacles;


DECLARE 
BEGIN
gest_Spectacles.ajoutSpectacle(seq_spectacle.NEXTVAL,'AMIRA','28/12/2022',14,2,400,2);
END;

DECLARE 
BEGIN
gest_Spectacles.ajoutRubrique(seq_rubrique.NEXTVAL,51,1,'28/12/2022',14,1,'theatre');
END;

BEGIN
gest_Spectacles.supprimerRubrique(48);
END;


create user AdminBD1 IDENTIFIED BY 123 ;
create user PlanificateurEvt1 IDENTIFIED BY 123;
create user GestCommandesBillets1 IDENTIFIED BY 123;


create role Gestion_Spectacles;
grant execute on gest_Spectacles to Gestion_Spectacles;
grant Gestion_Spectacles to PlanificateurEvt1;


create role Gestion_Utilisateurs;
grant execute on gest_utilisateurs to Gestion_Utilisateurs;
grant Gestion_Utilisateurs to AdminBD1;

create role Gestion_Privileges;
grant execute on gest_Privileges to Gestion_Privileges;
grant Gestion_Privileges to AdminBD1 ; 

create role Gestion_Commandes ;
grant execute on gest_commandes to Gestion_Commandes;
grant Gestion_Commandes to GestCommandesBillets1;


create user abc IDENTIFIED BY 123;
SELECT * FROM all_users;

CREATE OR REPLACE PACKAGE gest_utilisateurs IS
PROCEDURE chercher_utilisateur (nom all_users.username%TYPE );
PROCEDURE supprimer_utilisateur(username VARCHAR);
END gest_utilisateurs;

CREATE OR REPLACE PACKAGE BODY gest_utilisateurs IS
PROCEDURE supprimer_utilisateur(username VARCHAR) IS
   	Vusername   VARCHAR2 (30);
    errsup exception;
BEGIN
        Vusername := 'DROP USER ' || username ;
        EXECUTE IMMEDIATE (Vusername);
	    DBMS_OUTPUT.put_line( Vusername );
    commit ;
END supprimer_utilisateur;

PROCEDURE chercher_utilisateur (nom all_users.username%TYPE ) IS
    nb NUMBER;
    erreurt exception ; 
    BEGIN 
    SELECT count(username) into nb
	FROM ALL_USERS
    where username=nom;
    If (nb=0) then raise erreurt;
    else
	dbms_output.put_line('utilisateur existe');
    end if;
    exception 
    when erreurt then  dbms_output.put_line('utilisateur introuvable');
    END chercher_utilisateur ;
end gest_utilisateurs;

 -------------------  --------------------------
CREATE OR REPLACE PROCEDURE ajouter_utilisateur (username VARCHAR , mdp VARCHAR ) IS
Vusername   VARCHAR2 (30);
BEGIN
Vusername := 'CREATE USER ' || username || 'IDENTIFIED BY' || mdp ;
EXECUTE IMMEDIATE (Vusername);
END ajouter_utilisateur;
---------------------------
CREATE OR REPLACE PROCEDURE modifier_utilisateur (username varchar, mdp varchar, nvmdp varchar) IS
Vusername   VARCHAR2 (30);
BEGIN
Vusername := 'ALTER USER ' || username || 'IDENTIFIED BY' || mdp || 'REPLACE' || nvmdp;
EXECUTE IMMEDIATE (Vusername);
END modifier_utilisateur;
--------------------------
 DECLARE 
 BEGIN
 gest_utilisateurs.chercher_utilisateur('AAAA');
 END;