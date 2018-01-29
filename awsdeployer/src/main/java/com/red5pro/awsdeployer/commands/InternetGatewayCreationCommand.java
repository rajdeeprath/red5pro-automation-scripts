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
import com.amazonaws.services.ec2.model.AttachInternetGatewayRequest;
import com.amazonaws.services.ec2.model.AvailabilityZone;
import com.amazonaws.services.ec2.model.CreateInternetGatewayRequest;
import com.amazonaws.services.ec2.model.CreateInternetGatewayResult;
import com.amazonaws.services.ec2.model.CreateSubnetRequest;
import com.amazonaws.services.ec2.model.CreateSubnetResult;
import com.amazonaws.services.ec2.model.CreateTagsRequest;
import com.amazonaws.services.ec2.model.CreateVpcRequest;
import com.amazonaws.services.ec2.model.CreateVpcResult;
import com.amazonaws.services.ec2.model.DeleteVpcRequest;
import com.amazonaws.services.ec2.model.DeleteVpcResult;
import com.amazonaws.services.ec2.model.DescribeAvailabilityZonesResult;
import com.amazonaws.services.ec2.model.DescribeInternetGatewaysRequest;
import com.amazonaws.services.ec2.model.DescribeInternetGatewaysResult;
import com.amazonaws.services.ec2.model.DescribeSubnetsRequest;
import com.amazonaws.services.ec2.model.DescribeSubnetsResult;
import com.amazonaws.services.ec2.model.DescribeVpcsRequest;
import com.amazonaws.services.ec2.model.DescribeVpcsResult;
import com.amazonaws.services.ec2.model.Filter;
import com.amazonaws.services.ec2.model.InternetGateway;
import com.amazonaws.services.ec2.model.Subnet;
import com.amazonaws.services.ec2.model.Tag;
import com.amazonaws.services.ec2.model.Vpc;
import com.red5pro.awsdeployer.model.Configuration;

public class InternetGatewayCreationCommand implements Command {
	
	
	private Configuration configuration;
	
	private AWSCredentials credentials;
	
	private String[] targetRegions;
	
	
	
	public InternetGatewayCreationCommand()
	{
		
	}
	

	@Override
	public boolean execute(Context context) throws Exception 
	{
		System.out.println("Starting internet gateway creation");
		
		this.configuration = (Configuration) context.get("configuration");		
		this.credentials = (AWSCredentials) context.get("credentials");
		this. targetRegions = configuration.getStreamManagerRegions();
		
		/* For each  target regions */
		
		for(int i=0;i<this.targetRegions.length;i++)
		{
			String region = this.targetRegions[i];
			AmazonEC2 ec2Client = getEc2Client2(region);
			
			// Get vpc
			Filter name = new Filter().withName("tag:Name").withValues(configuration.getVpcName());
			Filter sessionId = new Filter().withName("tag:sessionid").withValues(configuration.getSessionId());
			
			DescribeVpcsRequest checkVpcRequest = new DescribeVpcsRequest().withFilters(new Filter[] {name, sessionId});
			DescribeVpcsResult vpcResponse = ec2Client.describeVpcs(checkVpcRequest);
			List<Vpc> vpcs = vpcResponse.getVpcs();
			
			if(vpcs.size() == 0)
			{
				throw new Exception("SEVERE : Vpc by name " + ec2Client + "not found by name");
			}
			
			Vpc vpc = vpcs.get(0);
			String igwName = "igw-" + configuration.getVpcName();
			
			Filter f1 = new Filter().withName("attachment.vpc-id").withValues(vpc.getVpcId());
			Filter f2 = new Filter().withName("tag:Name").withValues(igwName);
			Filter f3 = new Filter().withName("tag:sessionid").withValues(configuration.getSessionId());
			
			DescribeInternetGatewaysRequest request = new DescribeInternetGatewaysRequest().withFilters(f1,f2,f3);
			DescribeInternetGatewaysResult response = ec2Client.describeInternetGateways(request);
			List<InternetGateway> igws = response.getInternetGateways();
			
			if(igws.size() == 0)
			{
				System.out.print("Creating internet gateway...");
				
				// create internet gateway
				CreateInternetGatewayRequest igwCreateRequest = new CreateInternetGatewayRequest();
				CreateInternetGatewayResult igwCreateResponse = ec2Client.createInternetGateway(igwCreateRequest);
				InternetGateway igw = igwCreateResponse.getInternetGateway();
				
				System.out.print("Attaching internet gateway to vpc...");
				
				// attach to vpc
				 AttachInternetGatewayRequest attachInternetGatewayRequest = new AttachInternetGatewayRequest() .withInternetGatewayId(igw.getInternetGatewayId()) .withVpcId(vpc.getVpcId());
				 ec2Client.attachInternetGateway(attachInternetGatewayRequest);
				 
				 
				 System.out.print("Internet gateway attached to Vpc.....");
			}
			else
			{
				System.err.println("Internetgateway already exiss for the vpc " + vpc.getVpcId() + " with name " + igwName);
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
