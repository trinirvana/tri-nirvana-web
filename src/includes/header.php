<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo isset($pageTitle) ? $pageTitle . ' - ' . SITE_NAME : SITE_NAME; ?></title>
    <link rel="stylesheet" href="<?php echo SITE_URL; ?>/public/css/style.css">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <div class="nav-brand">
                <a href="<?php echo SITE_URL; ?>">
                    <i class="fas fa-swimming-pool"></i>
                    Tri Nirvana AI
                </a>
            </div>
            <ul class="nav-menu">
                <li><a href="<?php echo SITE_URL; ?>">Home</a></li>
                <li><a href="<?php echo SITE_URL; ?>/tools">Tools</a></li>
                <li><a href="<?php echo SITE_URL; ?>/about">About</a></li>
                <li><a href="<?php echo SITE_URL; ?>/contact">Contact</a></li>
            </ul>
            <div class="nav-toggle">
                <span></span>
                <span></span>
                <span></span>
            </div>
        </div>
    </nav>
    <main>