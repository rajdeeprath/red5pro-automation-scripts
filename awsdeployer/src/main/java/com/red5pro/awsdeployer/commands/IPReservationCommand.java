package com.red5pro.awsdeployer.commands;

import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

import org.apache.commons.chain.Command;
import org.apache.commons.chain.Context;

import com.amazonaws.AmazonServiceException;
import com.amazonaws.auth.AWSCredentials;
import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.services.ec2.AmazonEC2;
import com.amazonaws.services.ec2.AmazonEC2ClientBuilder;
import com.amazonaws.services.ec2.model.Address;
import com.amazonaws.services.ec2.model.AllocateAddressRequest;
import com.amazonaws.services.ec2.model.AllocateAddressResult;
import com.amazonaws.services.ec2.model.CreateTagsRequest;
import com.amazonaws.services.ec2.model.DescribeAddressesRequest;
import com.amazonaws.services.ec2.model.DescribeAddressesResult;
import com.amazonaws.services.ec2.model.DomainType;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.ReleaseAddressRequest;
import com.amazonaws.services.ec2.model.ReleaseAddressResult;
import com.amazonaws.services.ec2.model.Tag;
import com.red5pro.awsdeployer.model.Configuration;

public class IPReservationCommand implements Command {
	
	private Configuration configuration;
	
	private AWSCredentials credentials;
	
	private String[] targetRegions;
	
	private List<Address> existingIps = new ArrayList<Address>();
	
	private List<String> reservedIps = new ArrayList<String>();
	
	
	public IPReservationCommand()
	{
		
	}
	
	
	

	@Override
	public boolean execute(Context context) throws Exception 
	{
		System.out.println("Reserving IP address");
		
		this.configuration = (Configuration) context.get("configuration");		
		this.credentials = (AWSCredentials) context.get("credentials");
		this. targetRegions = configuration.getStreamManagerRegions();
		
		
		
		/* For each  target regions */
		
		for(int i=0;i<this. targetRegions.length;i++)
		{
			List<String> resources = new ArrayList<String>();
			AmazonEC2 ec2Client = getEc2Client2(targetRegions[i]);
			
			try
			{
				
				/* Describe IP addresses - check if exists */
				
				try
				{
					Filter f = new Filter().withName("tag:sessionid").withValues(configuration.getSessionId());
					DescribeAddressesRequest req = new DescribeAddressesRequest().withFilters(new Filter[]{f});
					DescribeAddressesResult response = ec2Client.describeAddresses(req);
					
					for(Address address : response.getAddresses()) 
					{
						System.out.printf( "Found address with public IP %s, " +    "domain %s, " +        "allocation id %s " +       "and NIC id %s",     address.getPublicIp(),      address.getDomain(),       address.getAllocationId(),       address.getNetworkInterfaceId());
						existingIps.add(address);
					}
					
					
					if(existingIps.size() > 0)
					{
						Scanner in = new Scanner(System.in);
						System.out.print("One or more reserved IP addresses found for the sessionId " + configuration.getSessionId() + ".Do you want me to remove these and reserve new ones ?");
						String a = in.next();
						
						if(a != null && a.toLowerCase().equalsIgnoreCase("y"))
						{
							System.out.print("Attempting to release reserved IPs");
							String error;
							
							for(Address address : existingIps)
							{
								if(address.getAssociationId() != null && address.getAllocationId() != "" )
								{
									error = "This IP seems to be associated with an instance. Aborting procedure!!";
									
									System.err.print(error);
									continue;
								}
								
								ReleaseAddressRequest request = new ReleaseAddressRequest()
					            .withAllocationId(address.getAllocationId());

								ReleaseAddressResult releaseResponse = ec2Client.releaseAddress(request);
								System.out.printf( "Successfully released elastic IP address %s", address.getPublicIp());
							}
							
						}
						else
						{
							throw new Exception("Cannot complete process since reserved IPs already exists. Please start a new session or delete the reserved IPs before proceeding.");
						}
					}
				}
				catch (AmazonServiceException e) 
				{
			        System.err.println("Error tagging resources");
			    	System.err.println("Caught Exception: " + e.getMessage());
			        System.err.println("Reponse Status Code: " + e.getStatusCode());
			        System.err.println("Error Code: " + e.getErrorCode());
			        System.err.println("Request ID: " + e.getRequestId());
			        
			        throw new Exception("Failed in creating elastic IP resources");
				}
				
				
				
				/* Create IP addresses */
				
				try
				{
					AllocateAddressRequest allocate_request = new AllocateAddressRequest() .withDomain(DomainType.Vpc);
					AllocateAddressResult allocate_response =    ec2Client.allocateAddress(allocate_request);
					String allocation_id = allocate_response.getAllocationId();
					String allocatedIP = allocate_response.getPublicIp();
					
					System.out.println("Ec2 address " + allocatedIP + " reserved @ region : " + targetRegions[i]);
					resources.add(allocation_id);
					
					reservedIps.add(allocatedIP);
				}
				catch (AmazonServiceException e) 
				{
			        System.err.println("Error tagging resources");
			    	System.err.println("Caught Exception: " + e.getMessage());
			        System.err.println("Reponse Status Code: " + e.getStatusCode());
			        System.err.println("Error Code: " + e.getErrorCode());
			        System.err.println("Request ID: " + e.getRequestId());
			        
			        throw new Exception("Failed in creating elastic IP resources");
				}
				
				
				
				/* Tag IP addresses */
				
				try 
				{
					System.out.println("Tagging Ec2 addresses...");
					
					List<Tag> tags = new ArrayList<Tag>();
					tags.add(new Tag("sessionid", configuration.getSessionId()));
					
					CreateTagsRequest createTagsRequest = new CreateTagsRequest();
					createTagsRequest.setResources(resources);
					createTagsRequest.setTags(tags);
					
					ec2Client.createTags(createTagsRequest);
				} 
				catch (AmazonServiceException e) 
				{
			        System.err.println("Error tagging resources");
			    	System.err.println("Caught Exception: " + e.getMessage());
			        System.err.println("Reponse Status Code: " + e.getStatusCode());
			        System.err.println("Error Code: " + e.getErrorCode());
			        System.err.println("Request ID: " + e.getRequestId());
			        
			        throw new Exception("Failed in creating elastic IP resources");
				}
			}
			catch(Exception e)
			{
				ec2Client = null;
				e.printStackTrace();
			}
		}
		
		return false;
	}
	
	
	
	AmazonEC2 getEc2Client2(String region){
		AmazonEC2 ec2 = AmazonEC2ClientBuilder.standard()
                .withRegion(region)
                .withCredentials(new AWSStaticCredentialsProvider(credentials))
                .build();
		
		return ec2;
	}

}
