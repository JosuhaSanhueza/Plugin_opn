<?php

namespace OPNsense\GameControl;

use OPNsense\Base\IndexController as BaseIndexController;

class IndexController extends BaseIndexController
{
    public function indexAction()
    {
        $this->view->title = gettext("Escolarapp Game Manager");
        $this->view->pick('OPNsense/GameControl/index');
    }
}
