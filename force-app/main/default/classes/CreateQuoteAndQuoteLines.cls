global class CreateQuoteAndQuoteLines{
    
    @InvocableMethod(Label='CreateOpportunityAndQuoteOnUserRequest' description='Creates an Opportunity and Quote based on user request')
    global static List<QuoteResponse> processRequests(List<Request> requests) {
        Request req = requests[0];
        Account acc = [ SELECT Id, Name from Account WHERE AccountNumber = :req.accNumber ];
        
        Opportunity opp = new Opportunity(
            Name = 'New Opportunity for '+acc.Name,
            AccountId = acc.Id,
            StageName = 'Propose',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        
        // Create Quote
        Quote quote = new Quote(
            Name = 'New Quote for '+acc.Name,
            OpportunityId = opp.Id,
            EndDate = req.endDate,
            Status = 'Draft'
        );
        insert quote;
        
        QuoteResponse response = new QuoteResponse();
        response.newQuote = quote;

        List<QuoteResponse> responseList = new List<QuoteResponse>();
        responseList.add(response);

        return responseList; 
       
    }

    global class Request {
        @InvocableVariable(label='Account Number' description='Account Number of the Account for which user wants to create Opportunity and QUote')
        public String accNumber;
        
        @InvocableVariable(label='End Date' description='End Date of the Quote')
        public Date endDate;
        
        
        /*@InvocableVariable
        public String catalog;
        @InvocableVariable
        public String category;
        @InvocableVariable
        public String childcategory;
        @InvocableVariable
        public String product;*/
        
    }

    global class QuoteResponse{
        @InvocableVariable(description='New Quote created for the user') 
        public Quote newQuote;
    }
}