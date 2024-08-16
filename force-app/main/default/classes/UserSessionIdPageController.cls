public with sharing class UserSessionIdPageController {
    public string getUserSessionId() {
        try {
            return UserInfo.getSessionId();
        } catch (Exception e) {
            System.debug('Error in userSessionIdPageController::'+ e);
            Log_Handler.store_Exception(e, 'UserSessionIdPageController', 'getUserSessionId');
            return null;
        }
    }
}