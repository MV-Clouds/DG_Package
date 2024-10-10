public class AuthorizationCodeController {
    public AuthorizationCodeController(ApexPages.StandardController c) {
    }

    public String code {
        get {
            String url = ApexPages.currentPage().getUrl();
            return extractCodeParameter(url);
        }
    }
        public static String extractCodeParameter(String url) {
            String relativePath = url.replace(System.Url.getSalesforceBaseUrl().toExternalForm(), '');
            PageReference pageRef = new PageReference(relativePath);
            String codeParameter = pageRef.getParameters().get('code');
            if(codeParameter == null){
                return 'ERROR: PERMISSION ISSUE';
            }
            
            String scope = pageRef.getParameters().get('scope');
            if(scope.contains('https://www.googleapis.com/auth/drive.file')){
                Integer index = codeParameter.indexOf('%2F');
                if (index == 1) {
                    codeParameter = codeParameter.substring(0, index) + '/' + codeParameter.substring(index + 3);
                }
            System.debug(codeParameter);
            return codeParameter;
            }
            return 'ERROR : PERMISSION ISSUE';

        }
    
    
}