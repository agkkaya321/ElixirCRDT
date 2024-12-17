# Système Distribué avec CRDT, Élection de Leader et Serveur Web en Elixir

Bienvenue dans ce projet de système distribué développé en Elixir, intégrant des concepts avancés tels que les CRDT (Conflict-free Replicated Data Types), l'implémentation d'un leader, ainsi qu'un serveur web robuste. Ce projet vise à démontrer comment construire une application distribuée résiliente et évolutive en utilisant les capacités concurrentes et distribuées d'Elixir.

## Table des Matières

- [Introduction](#introduction)
- [Fonctionnalités](#fonctionnalités)
- [Concepts Clés](#concepts-clés)
  - [CRDT (Conflict-free Replicated Data Types)](#crdt-conflict-free-replicated-data-types)
  - [Élection de Leader](#élection-de-leader)
  - [Serveur Web en Elixir](#serveur-web-en-elixir)
- [Architecture du Projet](#architecture-du-projet)
  - [SupervisorNode](#supervisornode)
  - [WorkerProcess](#workerprocess)
  - [PNCounter](#pncounter)
  - [Webserverex](#webserverex)
- [Installation](#installation)
- [Utilisation](#utilisation)
- [Contribuer](#contribuer)
- [Licence](#licence)

## Introduction

Ce projet illustre une architecture distribuée où plusieurs nœuds (workers) interagissent avec un superviseur central pour maintenir un état cohérent grâce aux CRDT. De plus, une interface web permet d'interagir avec le système, offrant une visualisation en temps réel des compteurs de produits.

## Fonctionnalités

- **Synchronisation Automatique** : Utilisation des CRDT pour assurer une synchronisation sans conflit des données entre les nœuds.
- **Élection de Leader** : Implémentation d'un mécanisme d'élection de leader pour gérer la coordination des opérations.
- **Serveur Web Intégré** : Interface web développée en Elixir pour interagir et visualiser l'état du système.
- **Résilience et Tolérance aux Pannes** : Capacité à gérer les déconnexions de nœuds et à maintenir la cohérence des données.
- **Extensibilité** : Architecture modulaire facilitant l'ajout de nouvelles fonctionnalités ou nœuds.

## Concepts Clés

### CRDT (Conflict-free Replicated Data Types)

Les CRDT sont des structures de données conçues pour être répliquées sur plusieurs nœuds de manière à ce que toutes les répliques puissent être mises à jour indépendamment sans coordination, tout en garantissant que toutes les répliques convergent vers le même état final. Dans ce projet, nous utilisons le `PNCounter` (Positive-Negative Counter), un type de CRDT qui permet des opérations d'incrément et de décrément sans conflits.

### Élection de Leader

L'élection de leader est un processus permettant de désigner un nœud principal (leader) parmi plusieurs nœuds participants. Ce leader est responsable de la coordination des opérations et de la gestion de l'état global. Dans notre implémentation, le leader est déterminé en fonction de la présence ou non d'autres nœuds connectés.

### Serveur Web en Elixir

Le serveur web intégré, développé avec Elixir et Plug.Cowboy, offre une interface utilisateur pour interagir avec le système. Il permet de visualiser les compteurs de produits, d'envoyer des mises à jour et de surveiller l'état des différents nœuds.

## Architecture du Projet

### SupervisorNode

Le `SupervisorNode` est le nœud central qui supervise les workers. Il gère les connexions des nœuds, surveille leur état, et maintient la liste des nœuds connectés. Il reçoit également les mises à jour des compteurs depuis les workers et les diffuse aux autres nœuds.

### WorkerProcess

Chaque `WorkerProcess` est un nœud qui se connecte au superviseur. Il maintient des compteurs locaux pour différents produits en utilisant les `PNCounter`. Les workers peuvent être leaders ou suiveurs, et ils synchronisent leurs états en fonction des mises à jour reçues.

### PNCounter

Le module `PNCounter` implémente un compteur positif-négatif, un type de CRDT permettant des opérations d'incrément et de décrément sans conflits. Il assure que les compteurs restent cohérents à travers les différentes répliques du système.

### Webserverex

Le module `Webserverex.Application` démarre un serveur web qui permet aux utilisateurs d'interagir avec le système via une interface web. Il se connecte au superviseur et envoie des messages pour mettre à jour les compteurs des produits.

## Installation

### Prérequis

- **Elixir** : Assurez-vous d'avoir Elixir installé. Vous pouvez le télécharger depuis [elixir-lang.org](https://elixir-lang.org/install.html).
- **Erlang/OTP** : Nécessaire pour exécuter Elixir.

### Étapes

1. **Cloner le dépôt**

   ```bash
   git clone https://github.com/votre-utilisateur/votre-projet.git
   cd votre-projet
   mix deps.get
   iex supervisor.exs
   iex worker.exs
   mix run --no-halt

