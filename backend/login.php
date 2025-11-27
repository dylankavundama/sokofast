<?php
session_start();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';

    // ATTENTION SÉCURITÉ :
    // Ces identifiants sont fixes et ne doivent JAMAIS être utilisés en production.
    // Pour une application réelle, vous devriez :
    // 1. Récupérer les identifiants d'une base de données.
    // 2. Hacher les mots de passe lors de l'enregistrement (ex: password_hash()).
    // 3. Vérifier le mot de passe haché lors de la connexion (ex: password_verify()).
    if ($username === 'admin' && $password === 'soko') {
        $_SESSION['admin_logged_in'] = true;
        // Important: Set $_SESSION['loggedin'] as well, as your gestion_commandes.php checks for it
        $_SESSION['loggedin'] = true;
        
        // Change 'index.php' to the actual filename of your order management page
        header("Location: index.php"); 
        exit;
    } else {
        $error = "Nom d'utilisateur ou mot de passe incorrect.";
    }
}
?>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Soko Fast</title>
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary-color: #000000;
            --primary-dark: #0056b3;
            --secondary-bg: #f8f9fa;
            --text-color: #333;
            --border-color: #ced4da;
            --error-color: #dc3545;
            --shadow-light: rgba(0, 0, 0, 0.08);
            --shadow-medium: rgba(0, 0, 0, 0.15);
        }

        body {
            font-family: 'Roboto', sans-serif;
            background: linear-gradient(135deg, #f8f9fa 0%); /* Dégradé de fond */
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            color: var(--text-color);
        }

        .login-container {
            background: #fff;
            padding: 40px 30px;
            border-radius: 12px;
            box-shadow: 0 10px 30px var(--shadow-medium);
            width: 100%;
            max-width: 400px;
            text-align: center;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        .login-container:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 40px var(--shadow-medium);
        }

        .logo {
            margin-bottom: 25px;
        }

        .logo img {
            width: 100px; /* Taille du logo */
            height: auto;
            border-radius: 50%; /* Pour un logo rond si désiré */
            box-shadow: 0 4px 10px var(--shadow-light);
        }

        h2 {
            font-size: 1.8em;
            margin-bottom: 30px;
            color: var(--primary-color);
            position: relative;
        }

        h2::after {
            content: '';
            position: absolute;
            left: 50%;
            bottom: -10px;
            transform: translateX(-50%);
            width: 60px;
            height: 3px;
            background-color: var(--primary-color);
            border-radius: 2px;
        }

        .input-group {
            margin-bottom: 20px;
            text-align: left;
        }

        .input-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 500;
            color: #555;
        }

        input[type="text"],
        input[type="password"] {
            width: 100%;
            padding: 12px 15px;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            box-sizing: border-box;
            font-size: 1em;
            transition: border-color 0.3s ease, box-shadow 0.3s ease;
        }

        input[type="text"]:focus,
        input[type="password"]:focus {
            border-color: var(--primary-color);
            outline: none;
            box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.25);
        }

        button {
            width: 100%;
            padding: 14px;
            margin-top: 20px;
            border-radius: 8px;
            border: none;
            background: var(--primary-color);
            color: #fff;
            font-size: 1.1em;
            font-weight: 500;
            cursor: pointer;
            transition: background 0.3s ease, transform 0.1s ease;
            box-shadow: 0 4px 15px rgba(0, 123, 255, 0.3);
        }

        button:hover {
            background: var(--primary-dark);
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0, 123, 255, 0.4);
        }

        button:active {
            transform: translateY(0);
            box-shadow: 0 2px 10px rgba(0, 123, 255, 0.2);
        }

        .error {
            color: var(--error-color);
            margin-top: 15px;
            font-size: 0.95em;
            background-color: #ffebeb;
            border-left: 5px solid var(--error-color);
            padding: 10px 15px;
            border-radius: 4px;
        }

        .footer-links {
            margin-top: 25px;
            font-size: 0.9em;
        }

        .footer-links a {
            color: var(--primary-color);
            text-decoration: none;
            margin: 0 10px;
            transition: color 0.3s ease;
        }

        .footer-links a:hover {
            color: var(--primary-dark);
            text-decoration: underline;
        }

        /* Responsive */
        @media (max-width: 768px) {
            body {
                padding: 20px;
            }

            .login-container {
                padding: 30px 20px;
                max-width: 100%;
            }

            h2 {
                font-size: 1.5em;
            }

            .logo img {
                width: 80px;
            }

            input[type="text"],
            input[type="password"] {
                padding: 10px 12px;
                font-size: 0.95em;
            }

            button {
                padding: 12px;
                font-size: 1em;
            }
        }

        @media (max-width: 576px) {
            .login-container {
                padding: 25px 15px;
            }

            h2 {
                font-size: 1.3em;
            }

            .logo img {
                width: 70px;
            }

            .input-group {
                margin-bottom: 15px;
            }

            .input-group label {
                font-size: 0.9em;
            }
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="logo">
            <img src="./icon.png" alt="Logo de l'application">
        </div>
        <h2>Soko Fast</h2>
        <form method="POST" action="">
            <div class="input-group">
                <label for="username">Nom d'utilisateur</label>
                <input type="text" id="username" name="username" placeholder="Entrez votre nom d'utilisateur" required>
            </div>
            <div class="input-group">
                <label for="password">Mot de passe</label>
                <input type="password" id="password" name="password" placeholder="Entrez votre mot de passe" required>
            </div>
            <button type="submit">Se connecter</button>
            <?php if (!empty($error)) echo "<div class='error'>$error</div>"; ?>
        </form>
        <div class="footer-links">
            <a href="#">Besoin d'aide ?</a>
        </div>
    </div>
</body>
</html>